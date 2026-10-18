extends VBoxContainer
## A bounded index and one live reading. Selection is presentation state only.
const T=preload("res://scripts/hud/hud_tokens.gd")
var state:Dictionary={}
var records:Array=[]
var page_size:=6
var configured_limit:=6
var search:LineEdit
var spread:BoxContainer
var index:VBoxContainer
var tiles:=false
var choices:Container
var reader:VBoxContainer
var back:Button
var counter:Label
var previous:Button
var next:Button
var _narrow:=false

func setup(saved:Dictionary,limit:int=6)->void:
	state=saved;page_size=limit;configured_limit=limit
	if not state.has("reading"):state.reading=true
	add_theme_constant_override("separation",8)
	spread=BoxContainer.new();spread.add_theme_constant_override("separation",18);add_child(spread)
	index=VBoxContainer.new();index.custom_minimum_size.x=236;index.add_theme_constant_override("separation",6);spread.add_child(index)
	search=LineEdit.new();search.name="Search";search.placeholder_text="Find by name or condition";search.custom_minimum_size.y=40;search.text=String(state.get("query",""));index.add_child(search)
	search.text_changed.connect(func(value:String):state.query=value;state.page=0;state.reading=false;refresh())
	choices=GridContainer.new() if tiles else VBoxContainer.new();choices.name="Choices";choices.add_theme_constant_override("separation",5);index.add_child(choices)
	var pages:=HBoxContainer.new();pages.add_theme_constant_override("separation",5);index.add_child(pages)
	previous=_button("‹","Previous choices");pages.add_child(previous);previous.pressed.connect(func():state.page=int(state.get("page",0))-1;refresh())
	counter=T.make_label("",13,T.INK_MUTED);counter.size_flags_horizontal=Control.SIZE_EXPAND_FILL;counter.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;pages.add_child(counter)
	next=_button("›","Next choices");pages.add_child(next);next.pressed.connect(func():state.page=int(state.get("page",0))+1;refresh())
	reader=VBoxContainer.new();reader.name="SelectedReading";reader.size_flags_horizontal=Control.SIZE_EXPAND_FILL;reader.add_theme_constant_override("separation",8);spread.add_child(reader)
	back=_button("Back to choices","Return to the same search and page");back.visible=false;reader.add_child(back);back.pressed.connect(func():state.reading=false;_layout())
	resized.connect(_layout)

func add_record(key:String,title:String,summary:String,content:Control)->void:
	records.append({"key":key,"title":title,"summary":summary,"content":content})
	reader.add_child(content);content.visible=false

func select(key:String)->void:
	state.selected=key;state.reading=true;refresh()

func refresh()->void:
	if choices==null:return
	for child in choices.get_children():choices.remove_child(child);child.queue_free()
	var query:=String(state.get("query","")).strip_edges().to_lower()
	var matched:Array=records.filter(func(record:Dictionary)->bool:return query.is_empty() or (String(record.title)+" "+String(record.summary)).to_lower().contains(query))
	var page:=clampi(int(state.get("page",0)),0,maxi(0,ceili(float(matched.size())/page_size)-1));state.page=page
	var visible_records:=matched.slice(page*page_size,(page+1)*page_size)
	var selected:=String(state.get("selected",""))
	if not visible_records.any(func(record:Dictionary)->bool:return String(record.key)==selected):
		selected=String(visible_records[0].key) if not visible_records.is_empty() else "";state.selected=selected
	for record:Dictionary in visible_records:
		var key:=String(record.key)
		var choice:=_button(String(record.title)+( "\n"+String(record.summary) if not String(record.summary).is_empty() else ""),String(record.title)+"\n"+String(record.summary))
		choice.name="Choice_"+key;choice.alignment=HORIZONTAL_ALIGNMENT_LEFT;choice.clip_text=true;choice.size_flags_horizontal=Control.SIZE_EXPAND_FILL;choice.custom_minimum_size.y=52
		if record.get("icon") is Texture2D:
			choice.icon=record.icon;choice.expand_icon=true;choice.add_theme_constant_override("icon_max_width",28)
		if tiles:choice.custom_minimum_size.y=84
		choice.toggle_mode=true;choice.set_pressed_no_signal(key==selected);choice.pressed.connect(func():select(key));choices.add_child(choice)
	if matched.is_empty():choices.add_child(T.make_label("No matching choices",15,T.INK_MUTED))
	for record:Dictionary in records:(record.content as Control).visible=String(record.key)==selected
	counter.text="%d · %d/%d" % [matched.size(),page+1,maxi(1,ceili(float(matched.size())/page_size))]
	previous.disabled=page==0;next.disabled=(page+1)*page_size>=matched.size()
	search.visible=records.size()>page_size or not query.is_empty()
	previous.get_parent().visible=records.size()>page_size
	_layout()

func update_record(key:String,title:String,summary:String)->void:
	for record:Dictionary in records:
		if String(record.key)!=key:continue
		record.title=title;record.summary=summary
		var choice:=choices.get_node_or_null("Choice_"+key) as Button
		if choice!=null:choice.text=title+("\n"+summary if not summary.is_empty() else "");choice.tooltip_text=title+"\n"+summary
		return

func _layout()->void:
	if spread==null:return
	_narrow=size.x>0 and size.x<700
	var limit:=mini(4,configured_limit) if size.x>0 and size.x<1000 else configured_limit
	if page_size!=limit:
		# Changing the number of choices must keep the player's current reading.
		var query:=String(state.get("query","")).strip_edges().to_lower()
		var matched:Array=records.filter(func(record:Dictionary)->bool:return query.is_empty() or (String(record.title)+" "+String(record.summary)).to_lower().contains(query))
		var selected:=String(state.get("selected",""))
		for i in matched.size():
			if String(matched[i].key)==selected:state.page=floori(float(i)/limit);break
		page_size=limit;call_deferred("refresh")
	spread.vertical=_narrow or tiles
	if tiles:(choices as GridContainer).columns=3 if size.x>=1000 else 2 if size.x>=600 else 1
	index.custom_minimum_size.x=0 if _narrow or tiles else 236
	index.size_flags_horizontal=Control.SIZE_EXPAND_FILL if _narrow or tiles else Control.SIZE_FILL
	var reading:=bool(state.get("reading",false)) and not String(state.get("selected","")).is_empty()
	index.visible=records.size()>1 and (not _narrow or not reading)
	reader.visible=not _narrow or reading or records.size()<=1
	back.visible=_narrow and reading and records.size()>1

func _button(caption:String,tip:String)->Button:
	var button:=Button.new();button.text=caption;button.tooltip_text=tip;button.custom_minimum_size.y=40;T.apply_button_style(button);return button
