extends VBoxContainer
## One retained dashboard: current readings, chart and one chosen explanation.
## Daily updates preserve the selected discovery/month, focus and scroll position.
const T:=preload("res://scripts/hud/hud_tokens.gd")
const Chart:=preload("res://scripts/hud/health_history_chart.gd")
const Era:=preload("res://scripts/hud/era_words.gd")
const Reasons:=preload("res://scripts/hud/life_change_words.gd")
var data:Dictionary={}
var topic:=0
var selected_day:=-1
var _metrics:GridContainer
var _metric_labels:Array=[]
var _columns:BoxContainer
var _chart:Control
var _month:Label
var _previous:Button
var _next:Button
var _month_text:Label
var _alert:Label
var _status:Label
var _topics:Array[Button]=[]
var _detail:VBoxContainer
var _detail_scroll:ScrollContainer
var _detail_key:=""

func setup(block:Dictionary)->void:
	name="HealthDashboard"
	theme=T.control_theme()
	size_flags_horizontal=SIZE_EXPAND_FILL
	add_theme_constant_override("separation",12)
	_metrics=GridContainer.new();_metrics.columns=4
	_metrics.add_theme_constant_override("h_separation",18);add_child(_metrics)
	for index in 4:
		var column:=_column(_metrics)
		_metric_labels.append([_label(column,"",12,T.MUTED),_label(column,"",26,T.INK),_label(column,"",12,T.MUTED)])
	_alert=_label(self,"",14,T.RED_TEXT)
	_columns=BoxContainer.new();_columns.add_theme_constant_override("separation",20);add_child(_columns)
	var left:=_column(_columns);left.size_flags_stretch_ratio=1.3
	_label(left,"Lifespan over time",18,T.INK)
	_chart=Chart.new();left.add_child(_chart)
	_chart.point_selected.connect(_select_month)
	_label(left,"◆ Discovery recorded   ● Living conditions changed",12,T.MUTED)
	var navigation:=HBoxContainer.new();left.add_child(navigation)
	_previous=Button.new();_previous.text="‹";_previous.tooltip_text="Previous month";navigation.add_child(_previous)
	_month=_label(navigation,"",14,T.BODY)
	_next=Button.new();_next.text="›";_next.tooltip_text="Next month";navigation.add_child(_next)
	_previous.pressed.connect(func():_select_month(_chart.selected_index-1))
	_next.pressed.connect(func():_select_month(_chart.selected_index+1))
	_month_text=_label(left,"",14,T.BODY)
	_month_text.max_lines_visible=5
	_month_text.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	_status=_label(left,"",13,T.MUTED)
	var right:=_column(_columns)
	var tabs:=HFlowContainer.new();right.add_child(tabs)
	for index in 4:
		var button:=Button.new();button.text=["Research","Conditions","Care","Deaths"][index]
		button.toggle_mode=true;button.add_theme_font_size_override("font_size",13);tabs.add_child(button);_topics.append(button)
		button.pressed.connect(func():topic=index;_refresh_detail(true))
	_detail_scroll=ScrollContainer.new();_detail_scroll.custom_minimum_size.y=300
	_detail_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	_detail_scroll.size_flags_vertical=SIZE_EXPAND_FILL;right.add_child(_detail_scroll)
	_detail=_column(_detail_scroll)
	_detail.add_theme_constant_override("separation",3)
	resized.connect(_layout)
	update_block(block)
	call_deferred("_layout")

func _column(parent:Node)->VBoxContainer:
	var column:=VBoxContainer.new();column.size_flags_horizontal=SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation",8);parent.add_child(column);return column

func _label(parent:Node,text:String,font_size:int,color:Color)->Label:
	var label:=T.make_label(text,font_size,color);label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal=SIZE_EXPAND_FILL;parent.add_child(label);return label

func _layout()->void:
	if _columns==null:return
	_columns.vertical=size.x<760
	_metrics.columns=2 if size.x<650 else 4

func update_block(block:Dictionary)->bool:
	if not data.is_empty() and data.get("scope","")!=block.get("scope",""):
		selected_day=-1
	data=block
	var readings:Array=data.get("readings",[])
	for index in mini(4,readings.size()):
		var reading:Dictionary=readings[index]
		_metric_labels[index][0].text=reading.label
		_metric_labels[index][1].text=reading.value
		_metric_labels[index][1].tooltip_text=reading.get("tip","")
		_metric_labels[index][2].text=reading.get("delta","")
	_alert.text=data.get("alert","");_alert.visible=not _alert.text.is_empty()
	_status.text="Drinking need met: %d%%  ·  Sheltered: %d%%" % [int(data.get("water",0)),mini(100,int(data.get("housing",0)))]
	var history:Array=data.get("history",[])
	_chart.set_points(history)
	var selected:=maxi(0,history.size()-1)
	for index in history.size():
		var point:Dictionary=history[index]
		if int(point.get("day",0))==selected_day:selected=index
	_show_month(selected)
	_refresh_detail()
	_layout()
	return true

func _select_month(index:int)->void:
	var history:Array=data.get("history",[])
	if index<0 or index>=history.size():return
	selected_day=int((history[index] as Dictionary).get("day",0));_show_month(index)

func _show_month(index:int)->void:
	var history:Array=data.get("history",[])
	if history.is_empty():_month_text.text="The first monthly reading will appear here.";return
	var point:Dictionary=history[index]
	_month.text="%s · %.1f years" % [Era.when(int(point.get("day",0))),float(point.get("life_expectancy",0))]
	_previous.disabled=index==0;_next.disabled=index==history.size()-1
	_chart.selected_index=index;_chart.queue_redraw()
	if index==0:
		_month_text.text="First recorded reading. Life expectancy estimates a newborn's lifespan under these conditions."
		return
	var reasons:Array=point.get("reasons",[])
	var told:=Reasons.tell(reasons,float(point.get("delta",0)),index,history)
	var discovery:=String(point.get("marker_label","")) if point.get("marker_type","")=="discovery" else ""
	_month_text.text="%s this interval, all causes combined.\n%s%s" % [Era.life_change(float(point.get("delta",0))),"Discovered: "+discovery+".\n" if discovery!="" else "",String(told.why)]
	_month_text.tooltip_text=String(told.tip)

func _open_discovery(discovery:Dictionary)->void:
	var day:=int(discovery.get("day",-1))
	if day<0:return
	for month in (data.get("history",[]) as Array).size():
		if int(data.history[month].get("day",0))>=day:
			_select_month(month);return

func _refresh_detail(force:=false)->void:
	for index in _topics.size():_topics[index].set_pressed_no_signal(index==topic)
	var key:=str([topic,data.get("research",{}),data.get("conditions",[]),data.get("care",""),data.get("care_share",0),data.get("mortality",[])])
	if not force and key==_detail_key:return
	_detail_key=key
	for child in _detail.get_children():_detail.remove_child(child);child.queue_free()
	if force:_detail_scroll.scroll_vertical=0
	match topic:
		0:_research()
		1:
			var conditions:Array=data.get("conditions",[])
			if conditions.is_empty():_label(_detail,"Conditions will appear after the first daily reading.",14,T.MUTED)
			for condition:Dictionary in conditions:
				var row:=HBoxContainer.new();_detail.add_child(row)
				_label(row,String(condition.get("name","")),14,T.BODY)
				_label(row,String(condition.get("value","")),14,condition.get("value_color",T.TEAL))
				row.tooltip_text="%s\n%s" % [condition.get("detail",""),condition.get("tip","")]
		2:
			_label(_detail,"Care of the sick",18,T.INK)
			_label(_detail,String(data.get("care","")),14,T.BODY)
			if bool(data.get("care_unlocked",false)):
				_label(_detail,"Lore keepers assigned to care",13,T.MUTED)
				var buttons:=HFlowContainer.new();_detail.add_child(buttons)
				for share:float in [0.0,0.25,0.5]:
					var button:=Button.new();button.text="%d%%" % roundi(share*100);button.toggle_mode=true
					button.set_pressed_no_signal(is_equal_approx(float(data.care_share),share));buttons.add_child(button)
					button.pressed.connect(func():var callback:Callable=data.get("on_care",Callable());if callback.is_valid():callback.call(share))
				_label(_detail,"More care leaves fewer lore keepers learning.",13,T.MUTED)
		3:
			_label(_detail,"Annual risk at today's rate",16,T.INK)
			var causes:Array=data.get("mortality",[])
			if causes.is_empty():_label(_detail,"No causes recorded yet.",14,T.MUTED)
			for cause:Dictionary in causes:
				_label(_detail,"%s · %s" % [cause.name,cause.value],14,T.BODY).tooltip_text=cause.get("tip","")
				var bar:=ProgressBar.new();bar.show_percentage=false;bar.value=float(cause.get("ratio",0))*100;bar.custom_minimum_size.y=5;_detail.add_child(bar)

func _research()->void:
	var research:Dictionary=data.get("research",{})
	var totals:Array=research.get("totals",[])
	_label(_detail,"Research totals · points before limits",16,T.INK).tooltip_text="Unlocked: full use of learned methods. In use: adoption and available means today. Both reflect research focus, before shared limits and upkeep. These are health-effect points, not years of life."
	if totals.is_empty():_label(_detail,"No health-related research unlocked yet.",14,T.MUTED)
	else:
		var table:=GridContainer.new();table.name="ResearchTotals";table.columns=3
		table.add_theme_constant_override("h_separation",12);table.add_theme_constant_override("v_separation",1);_detail.add_child(table)
		for heading:String in ["Category","Unlocked","In use"]:_label(table,heading,12,T.MUTED)
		for total:Dictionary in totals:
			_label(table,String(total.label),13,T.BODY).tooltip_text="%s From %d discoveries." % [total.tip,int(total.count)]
			_label(table,_points(float(total.unlocked)),14,T.INK)
			_label(table,_points(float(total.amount)),14,T.TEAL)
	_label(_detail,"Latest three discoveries",16,T.INK)
	var recent:Array=research.get("recent",[])
	if recent.is_empty():_label(_detail,"New health-related discoveries will appear here.",13,T.MUTED)
	for item:Dictionary in recent.slice(0,3):
		var button:=Button.new();button.name="RecentDiscovery"+String(item.get("id",""))
		button.add_theme_stylebox_override("normal",StyleBoxEmpty.new())
		button.text=String(item.get("name",""));button.flat=true;button.alignment=HORIZONTAL_ALIGNMENT_LEFT
		button.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;button.add_theme_font_size_override("font_size",14)
		button.tooltip_text="%s\n%s" % [item.get("mechanism",""),item.get("record","")]
		_detail.add_child(button);button.pressed.connect(_open_discovery.bind(item))
		var effects:Array[String]=[]
		for effect:Dictionary in item.get("effects",[]):effects.append("%s %s" % [effect.label,effect.value])
		var summary:=_label(_detail,"%s · %.0f%% in use · %s" % [Era.when(int(item.day)) if int(item.get("day",-1))>=0 else "Date not recorded",float(item.get("adoption",0))*100,"; ".join(effects)],12,T.MUTED)
		summary.max_lines_visible=1;summary.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		summary.tooltip_text=summary.text
	# Enough room for all eleven categories and three brief discoveries at a
	# normal desktop width; a smaller window keeps an internal scroll fallback.
	_detail_scroll.custom_minimum_size.y=420 if not totals.is_empty() else 300

func _points(amount:float)->String:
	if is_zero_approx(amount):return "0"
	if absf(amount)*100<0.01:return ("+" if amount>0 else "−")+"<0.01"
	return "%+.2f" % (amount*100)

func view_state()->Dictionary:
	return {"topic":topic,"day":selected_day}

func restore_view_state(state:Dictionary)->void:
	topic=clampi(int(state.get("topic",0)),0,3)
	selected_day=int(state.get("day",-1))
	update_block(data)
