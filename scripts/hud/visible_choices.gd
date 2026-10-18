extends VBoxContainer
## A bounded, retained choice tray. Same item identity contract as a selector,
## with no popup; programmatic selection never issues a command.
const T=preload("res://scripts/hud/hud_tokens.gd")
signal item_selected(index:int)
var items:Array[Dictionary]=[]
var selected:=-1
var item_count:int:
	get:return items.size()
var disabled:=false:
	set(value):disabled=value;_schedule()
var fit_to_longest_item:=false
var clip_text:=true
var flat:=false
var text_overrun_behavior:=TextServer.OVERRUN_TRIM_ELLIPSIS
var text:=""
var icon:Texture2D
var searchable:=true
var page_size:=6
var page:=0
var query:=""
var search:LineEdit
var flow:HFlowContainer
var pager:HBoxContainer
var previous:Button
var next:Button
var count:Label
var buttons:Array[Button]=[]
var _pending:=false

func _init()->void:
	add_theme_constant_override("separation",5)
	size_flags_horizontal=Control.SIZE_EXPAND_FILL
	search=LineEdit.new();search.name="FindChoice";search.placeholder_text="Find a choice";search.custom_minimum_size.y=36;add_child(search)
	search.text_changed.connect(func(value:String):query=value;page=0;_schedule())
	flow=HFlowContainer.new();flow.name="VisibleChoices";flow.add_theme_constant_override("h_separation",6);flow.add_theme_constant_override("v_separation",5);add_child(flow)
	for slot in page_size:
		var button:=Button.new();button.name="Choice"+str(slot);button.toggle_mode=true;button.clip_text=true;button.custom_minimum_size=Vector2(140,38);button.size_flags_horizontal=Control.SIZE_EXPAND_FILL;T.apply_button_style(button);flow.add_child(button);buttons.append(button)
		button.pressed.connect(func():_choose_visible(button))
	pager=HBoxContainer.new();pager.name="ChoicePages";add_child(pager)
	previous=Button.new();previous.text="‹";previous.tooltip_text="Previous choices";T.apply_button_style(previous);pager.add_child(previous)
	previous.pressed.connect(func():page=maxi(0,page-1);_schedule())
	count=T.make_label("",12,T.INK_MUTED);count.size_flags_horizontal=Control.SIZE_EXPAND_FILL;count.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;count.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;pager.add_child(count)
	next=Button.new();next.text="›";next.tooltip_text="Next choices";T.apply_button_style(next);pager.add_child(next)
	next.pressed.connect(func():page+=1;_schedule())
	resized.connect(_schedule)
	_schedule()

func _schedule()->void:
	if _pending:return
	_pending=true;_render.call_deferred()

func _render()->void:
	_pending=false
	var focused_key:Variant=null
	for button:Button in buttons:
		if button.has_focus():focused_key=button.get_meta("choice_key",null)
	var matches:Array[int]=[]
	for i in items.size():
		if query.strip_edges().is_empty() or String(items[i].text).to_lower().contains(query.strip_edges().to_lower()):matches.append(i)
	var pages:=maxi(1,ceili(float(matches.size())/page_size));page=clampi(page,0,pages-1)
	search.visible=searchable and (items.size()>page_size or not query.is_empty())
	pager.visible=items.size()>page_size or not query.is_empty();previous.disabled=page==0;next.disabled=page+1>=pages
	count.text="%d choices · %d/%d" % [matches.size(),page+1,pages]
	for slot in buttons.size():
		var button:=buttons[slot];var offset:=page*page_size+slot
		button.visible=offset<matches.size()
		if not button.visible:continue
		var i:=matches[offset];var item:Dictionary=items[i]
		button.set_meta("item",i);button.set_meta("choice_key",_item_key(item));button.text=String(item.text);button.tooltip_text=String(item.tip) if not String(item.tip).is_empty() else String(item.text)
		button.disabled=disabled or bool(item.disabled);button.set_pressed_no_signal(i==selected)
		button.icon=item.icon;button.expand_icon=true;button.add_theme_constant_override("icon_max_width",22)
		var label_width:=button.get_theme_font("font").get_string_size(button.text,HORIZONTAL_ALIGNMENT_LEFT,-1,button.get_theme_font_size("font_size")).x
		button.custom_minimum_size.x=minf(maxf(120,size.x),clampf(label_width+32+(28 if button.icon else 0),120,280))

	if focused_key!=null:
		var replacement:Button
		for button:Button in buttons:
			if button.visible and button.get_meta("choice_key",null)==focused_key:replacement=button;break
		if replacement:replacement.grab_focus()
		else:
			for button:Button in buttons:
				if button.has_focus():button.release_focus()

func _item_key(item:Dictionary)->Variant:
	return ["metadata",item.metadata] if item.metadata!=null else ["item",item.id,item.text]

func _choose_visible(button:Button)->void:
	var key:Variant=button.get_meta("choice_key",null)
	for index in items.size():
		if _item_key(items[index])==key:_choose(index);return

func _choose(index:int)->void:
	if index<0 or index>=items.size() or disabled or bool(items[index].disabled):return
	selected=index;_schedule();item_selected.emit(index)

func add_item(label:String,id:int=-1)->void:
	items.append({"text":label,"id":items.size() if id<0 else id,"metadata":null,"tip":"","disabled":false,"icon":null})
	if selected<0:selected=0
	_schedule()
func add_icon_item(texture:Texture2D,label:String,id:int=-1)->void:
	add_item(label,id);items.back().icon=texture
func clear()->void:items.clear();selected=-1;_schedule()
func select(index:int)->void:
	selected=index if index>=0 and index<items.size() else -1
	if query.is_empty() and selected>=0:page=floori(float(selected)/page_size)
	_schedule()
func get_selected_id()->int:return get_item_id(selected)
func get_selected_metadata()->Variant:return get_item_metadata(selected)
func get_item_count()->int:return items.size()
func get_item_id(index:int)->int:return int(items[index].id) if index>=0 and index<items.size() else -1
func get_item_index(id:int)->int:
	for i in items.size():
		if int(items[i].id)==id:return i
	return -1
func get_item_text(index:int)->String:return String(items[index].text) if index>=0 and index<items.size() else ""
func get_item_metadata(index:int)->Variant:return items[index].metadata if index>=0 and index<items.size() else null
func get_item_tooltip(index:int)->String:return String(items[index].tip) if index>=0 and index<items.size() else ""
func set_item_metadata(index:int,value:Variant)->void:items[index].metadata=value
func set_item_tooltip(index:int,value:String)->void:items[index].tip=value;_schedule()
func set_item_text(index:int,value:String)->void:items[index].text=value;_schedule()
func set_item_disabled(index:int,value:bool)->void:items[index].disabled=value;_schedule()

func is_item_disabled(index:int)->bool:return bool(items[index].disabled) if index>=0 and index<items.size() else true
