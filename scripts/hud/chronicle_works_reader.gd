extends VBoxContainer
## A building record is selected and read, rather than sixty accounts stacked.
const T:=preload("res://scripts/hud/hud_tokens.gd")
const PAGE_SIZE:=6
var data:Dictionary={}
var browsing:=false
var query:=""
var page:=0
var selected:=""
var materials_open:=false
var overview:VBoxContainer
var material_list:VBoxContainer
var materials_button:Button
var browse_button:Button
var search:LineEdit
var paging:HBoxContainer
var tally:Label
var previous:Button
var next:Button
var split:BoxContainer
var choices:VBoxContainer
var reader:VBoxContainer

func setup(block:Dictionary)->void:
	name="ChronicleWorksReader";data=block;theme=T.control_theme();add_theme_constant_override("separation",12)
	overview=VBoxContainer.new();overview.add_theme_constant_override("separation",8);add_child(overview)
	var totals:=HFlowContainer.new();totals.add_theme_constant_override("h_separation",18);totals.add_theme_constant_override("v_separation",6);overview.add_child(totals)
	for fact:Dictionary in data.get("facts",[]):
		var reading:=_label(totals,"%s %s" % [fact.value,String(fact.label).to_lower()],16,T.INK);reading.autowrap_mode=TextServer.AUTOWRAP_OFF;reading.tooltip_text=String(fact.get("tip",""))
	materials_button=_button(overview,"Materials used by all building ▸",func()->void:materials_open=not materials_open;_render())
	materials_button.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
	material_list=VBoxContainer.new();material_list.visible=false;overview.add_child(material_list)
	for material:Dictionary in data.get("materials",[]):_label(material_list,"%s · %s" % [material.label,material.value],14,T.INK_MUTED)
	browse_button=_button(self,"Browse all building records",func()->void:browsing=not browsing;_render())
	browse_button.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
	search=LineEdit.new();search.name="BuildingRecordSearch";search.placeholder_text="Search buildings, materials, dates or notes";search.clear_button_enabled=true;search.custom_minimum_size.y=40;add_child(search)
	search.text_changed.connect(func(text:String)->void:query=text;page=0;_render())
	paging=HBoxContainer.new();paging.add_theme_constant_override("separation",8);add_child(paging)
	previous=_button(paging,"Newer",func()->void:page-=1;_render())
	tally=_label(paging,"",14,T.INK_MUTED);tally.size_flags_horizontal=Control.SIZE_EXPAND_FILL;tally.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	next=_button(paging,"Older",func()->void:page+=1;_render())
	split=BoxContainer.new();split.add_theme_constant_override("separation",20);add_child(split)
	choices=VBoxContainer.new();choices.add_theme_constant_override("separation",6);split.add_child(choices)
	reader=VBoxContainer.new();reader.size_flags_horizontal=Control.SIZE_EXPAND_FILL;reader.add_theme_constant_override("separation",10);split.add_child(reader)
	resized.connect(_layout);_render()

func _button(parent:Node,text:String,action:Callable)->Button:
	var button:=Button.new();button.text=text;T.apply_button_style(button);button.pressed.connect(action);parent.add_child(button);return button

func _label(parent:Node,text:String,px:int,color:Color)->Label:
	var label:=T.make_label(text,px,color);label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;parent.add_child(label);return label

func _clear(parent:Node)->void:
	for child in parent.get_children():parent.remove_child(child);child.queue_free()

func matches()->Array:
	var out:Array=[]
	for record:Dictionary in data.get("records",[]):
		if not browsing or query.strip_edges().is_empty() or str(record.values()).to_lower().contains(query.strip_edges().to_lower()):out.append(record)
	return out

func _render()->void:
	if choices==null:return
	material_list.visible=materials_open;materials_button.text="Materials used by all building "+("▾" if materials_open else "▸")
	overview.visible=not browsing;search.visible=browsing;paging.visible=browsing
	browse_button.text="Back to recent building" if browsing else "Browse all %d building records" % (data.get("records",[]) as Array).size()
	_clear(choices);_clear(reader)
	var records:=matches();var pages:=maxi(1,ceili(float(records.size())/PAGE_SIZE));page=clampi(page,0,pages-1)
	tally.text="%d records · %d / %d" % [records.size(),page+1,pages];previous.disabled=page==0;next.disabled=page>=pages-1
	var shown:Array=records.slice(page*PAGE_SIZE,(page+1)*PAGE_SIZE) if browsing else records.slice(0,3)
	if shown.is_empty():_label(choices,"No record matches this search." if browsing else "Nothing has been built yet.",16,T.INK_MUTED);_layout();return
	if not shown.any(func(record:Dictionary)->bool:return String(record.key)==selected):selected=String(shown[0].key)
	_label(choices,"Building records" if browsing else "Recent building",18,T.INK)
	for record:Dictionary in shown:
		var item:=PanelContainer.new();item.name="WorkRecord";item.add_theme_stylebox_override("panel",T.flat(T.ACTIVE_BG if String(record.key)==selected else T.PAPER_RAISED,T.GOLD if String(record.key)==selected else T.BORDER_SOFT,1,4,6));choices.add_child(item)
		var button:=Button.new();button.flat=true;button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);button.accessibility_name="%s · %s · %s" % [record.title,record.event,record.date];item.add_child(button)
		button.pressed.connect(func()->void:selected=String(record.key);_render())
		var words:=VBoxContainer.new();words.mouse_filter=Control.MOUSE_FILTER_IGNORE;words.add_theme_constant_override("separation",2);item.add_child(words)
		var title:=_label(words,"%s · %s" % [record.title,record.event],16,T.INK);title.mouse_filter=Control.MOUSE_FILTER_IGNORE
		var when:=_label(words,String(record.date),14,T.INK_MUTED);when.mouse_filter=Control.MOUSE_FILTER_IGNORE
		if String(record.key)==selected:_read_record(record)
	_layout()

func _read_record(record:Dictionary)->void:
	_label(reader,String(record.title),24,T.INK)
	_label(reader,"%s · %s" % [record.date,record.event],14,T.INK_MUTED)
	if String(record.place)!="":_label(reader,String(record.place),16,T.INK)
	_label(reader,"Material used",18,T.INK)
	_label(reader,String(record.materials),16,T.BODY)
	if String(record.note)!="":_label(reader,String(record.note),16,T.BODY)

func _layout()->void:
	if split==null:return
	split.vertical=size.x<700
	split.move_child(reader if split.vertical else choices,0)
	choices.size_flags_horizontal=Control.SIZE_EXPAND_FILL if split.vertical else Control.SIZE_FILL
	choices.custom_minimum_size.x=0 if split.vertical else 310

func view_state()->Dictionary:
	return {"browse":browsing,"query":query,"page":page,"selected":selected,"materials":materials_open}

func restore_view_state(state:Dictionary)->void:
	browsing=bool(state.get("browse",false));query=String(state.get("query",""));page=int(state.get("page",0));selected=String(state.get("selected",""));materials_open=bool(state.get("materials",false))
	search.text=query;material_list.visible=materials_open;_render()
