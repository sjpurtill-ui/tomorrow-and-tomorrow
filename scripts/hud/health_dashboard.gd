extends VBoxContainer
## One retained dashboard: current readings, chart and one chosen explanation.
## Daily updates preserve the selected discovery/month, focus and scroll position.
const T:=preload("res://scripts/hud/hud_tokens.gd")
const Chart:=preload("res://scripts/hud/health_history_chart.gd")
const Era:=preload("res://scripts/hud/era_words.gd")
const Reasons:=preload("res://scripts/hud/life_change_words.gd")
var data:Dictionary={}
var topic:=0
var selected_id:=""
var selected_day:=-1
var selected_condition:=0
var _metrics:GridContainer
var _metric_labels:Array=[]
var _columns:BoxContainer
var _chart:Control
var _month:OptionButton
var _month_text:Label
var _alert:Label
var _status:Label
var _topics:Array[Button]=[]
var _picker:OptionButton
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
	_month=OptionButton.new();_month.name="Month";_month.fit_to_longest_item=false;left.add_child(_month)
	_month.item_selected.connect(func(index:int):_select_month(index))
	_month_text=_label(left,"",14,T.BODY)
	_month_text.max_lines_visible=5
	_month_text.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	_status=_label(left,"",13,T.MUTED)
	var right:=_column(_columns)
	var tabs:=HFlowContainer.new();right.add_child(tabs)
	for index in 4:
		var button:=Button.new();button.text=["Discoveries","Conditions","Care","Deaths"][index]
		button.toggle_mode=true;button.add_theme_font_size_override("font_size",13);tabs.add_child(button);_topics.append(button)
		button.pressed.connect(func():topic=index;_refresh_detail(true))
	_picker=OptionButton.new();_picker.name="HealthSelection";_picker.fit_to_longest_item=false;right.add_child(_picker)
	_picker.item_selected.connect(_choose)
	_detail_scroll=ScrollContainer.new();_detail_scroll.custom_minimum_size.y=300
	_detail_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	_detail_scroll.size_flags_vertical=SIZE_EXPAND_FILL;right.add_child(_detail_scroll)
	_detail=_column(_detail_scroll)
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
		selected_id="";selected_day=-1;selected_condition=0
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
	var labels:Array=[]
	var selected:=maxi(0,history.size()-1)
	for index in history.size():
		var point:Dictionary=history[index]
		labels.append("%s · %.1f years%s" % [Era.when(int(point.get("day",0))),float(point.get("life_expectancy",0))," ◆" if point.get("marker_type","")=="discovery" else ""])
		if int(point.get("day",0))==selected_day:selected=index
	_options(_month,labels,selected)
	_show_month(selected)
	_refresh_detail()
	_layout()
	return true

func _options(control:OptionButton,labels:Array,selected:int)->void:
	var changed:=control.item_count!=labels.size()
	if not changed:
		for index in labels.size():
			if control.get_item_text(index)!=String(labels[index]):changed=true;break
	if changed:
		control.clear()
		for text:String in labels:control.add_item(text)
	control.disabled=labels.is_empty()
	if not labels.is_empty():control.select(clampi(selected,0,labels.size()-1))

func _select_month(index:int)->void:
	var history:Array=data.get("history",[])
	if index<0 or index>=history.size():return
	selected_day=int((history[index] as Dictionary).get("day",0));_month.select(index);_show_month(index)

func _show_month(index:int)->void:
	var history:Array=data.get("history",[])
	if history.is_empty():_month_text.text="The first monthly reading will appear here.";return
	var point:Dictionary=history[index]
	_chart.selected_index=index;_chart.queue_redraw()
	if index==0:
		_month_text.text="First recorded reading. Life expectancy estimates a newborn's lifespan under these conditions."
		return
	var reasons:Array=point.get("reasons",[])
	var told:=Reasons.tell(reasons,float(point.get("delta",0)),index,history)
	var discovery:=String(point.get("marker_label","")) if point.get("marker_type","")=="discovery" else ""
	_month_text.text="%s this interval, all causes combined.\n%s%s" % [Era.life_change(float(point.get("delta",0))),"Discovered: "+discovery+".\n" if discovery!="" else "",String(told.why)]
	_month_text.tooltip_text=String(told.tip)

func _choose(index:int)->void:
	if topic==0:
		var discovery:Dictionary=data.discoveries[index]
		selected_id=String(discovery.id)
		var day:=int(discovery.get("day",-1))
		if day>=0:
			for month in (data.get("history",[]) as Array).size():
				if int(data.history[month].get("day",0))>=day:
					_select_month(month);break
	else:selected_condition=index
	_refresh_detail(true)

func _refresh_detail(force:=false)->void:
	for index in _topics.size():_topics[index].set_pressed_no_signal(index==topic)
	var entries:Array=data.get("discoveries",[]) if topic==0 else data.get("conditions",[])
	var labels:Array=[]
	var selected:=0
	for index in entries.size():
		var row:Dictionary=entries[index]
		labels.append(String(row.get("name","")))
		if topic==0 and String(row.get("id",""))==selected_id:selected=index
	if topic==1:selected=clampi(selected_condition,0,maxi(0,entries.size()-1))
	_picker.visible=topic<2
	_options(_picker,labels,selected)
	var item:Dictionary=entries[selected] if not entries.is_empty() else {}
	if topic==0 and not item.is_empty():selected_id=String(item.id)
	var key:=str([topic,item,data.get("care",""),data.get("care_share",0),data.get("mortality",[])])
	if not force and key==_detail_key:return
	_detail_key=key
	for child in _detail.get_children():_detail.remove_child(child);child.queue_free()
	if force:_detail_scroll.scroll_vertical=0
	match topic:
		0:_discovery(item)
		1:
			if item.is_empty():_label(_detail,"Conditions will appear after the first daily reading.",14,T.MUTED)
			else:
				_label(_detail,String(item.get("value","")),22,item.get("value_color",T.TEAL))
				_label(_detail,String(item.get("sub","")),14,T.MUTED)
				_label(_detail,String(item.get("detail","")),15,T.BODY)
				_label(_detail,String(item.get("tip","")),13,T.MUTED)
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

func _discovery(item:Dictionary)->void:
	if item.is_empty():
		_label(_detail,"No health-related discoveries yet",18,T.INK)
		_label(_detail,"Clean water, wound care, birth care and better food can improve survival. Their effects and spread will appear here as they are learned.",14,T.MUTED)
		return
	_label(_detail,"In use: %.1f%%  ·  Practised: %.1f%%" % [float(item.adoption)*100,float(item.practice)*100],16,T.TEAL)
	var bar:=ProgressBar.new();bar.show_percentage=false;bar.value=float(item.adoption)*100;bar.custom_minimum_size.y=7;_detail.add_child(bar)
	_label(_detail,String(item.get("mechanism","")),14,T.BODY)
	_label(_detail,"Health contributions before shared limits",14,T.INK)
	for effect:Dictionary in item.effects:
		_label(_detail,"%s  %s" % [effect.label,effect.value],14,T.BODY).tooltip_text=effect.tip
	if not (item.protections as Array).is_empty():
		_label(_detail,"Protection coverage · now / full use",13,T.MUTED)
		for protection:Dictionary in item.protections:
			_label(_detail,"%s  %s" % [protection.label,protection.value],14,T.BODY).tooltip_text=protection.tip
	_label(_detail,String(item.record),13,T.BODY)
	_label(_detail,"Effects grow as knowledge spreads. Shared limits, upkeep and overlapping protections apply; these points do not add directly to years of life.",12,T.MUTED)

func view_state()->Dictionary:
	return {"topic":topic,"id":selected_id,"day":selected_day,"condition":selected_condition}

func restore_view_state(state:Dictionary)->void:
	topic=clampi(int(state.get("topic",0)),0,3);selected_id=String(state.get("id",""))
	selected_day=int(state.get("day",-1));selected_condition=int(state.get("condition",0))
	update_block(data)
