extends VBoxContainer
## Three recent events, or a searchable six-result archive, beside one telling.
## The original related-report callbacks remain intact.
const T:=preload("res://scripts/hud/hud_tokens.gd")
const UI:=preload("res://scripts/hud/world_ui.gd")
const FILTERS:=[["all","All"],["contact","Peoples"],["war","War"],["scout","Scouts"]]
const PAGE:=6
const RECENT:=3
var model:Dictionary={}
var view:Dictionary={}
var chips:HFlowContainer
var heading:Label
var mode_button:Button
var search:LineEdit
var composition:BoxContainer
var browser:VBoxContainer
var list:VBoxContainer
var reader:VBoxContainer
var pager:HBoxContainer
var count:Label
var previous:Button
var next:Button

func setup(block:Dictionary)->void:
	name="WorldHistoryBoard";size_flags_horizontal=Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation",12);_take(block)
	var head:=HFlowContainer.new();head.add_theme_constant_override("h_separation",16);add_child(head)
	heading=UI.label(head,"Recently in the world",22,T.INK,true)
	mode_button=UI.verb(head,"Browse every event",func():set_archive(not bool(view.archive)));mode_button.name="Archive"
	chips=HFlowContainer.new();chips.name="Filters";chips.add_theme_constant_override("h_separation",6);chips.add_theme_constant_override("v_separation",4);add_child(chips)
	search=LineEdit.new();search.name="FindEvent";search.placeholder_text="Find an event, people or place";search.custom_minimum_size.y=40;search.size_flags_horizontal=Control.SIZE_EXPAND_FILL;search.add_theme_font_size_override("font_size",16);search.text=String(view.query);add_child(search)
	search.text_changed.connect(func(text:String):view.query=text;view.page=0;view.selected="";view.reader_open=false;redraw())
	composition=BoxContainer.new();composition.name="EventsAndTelling";composition.size_flags_horizontal=Control.SIZE_EXPAND_FILL;composition.add_theme_constant_override("separation",24);add_child(composition)
	browser=VBoxContainer.new();browser.size_flags_horizontal=Control.SIZE_EXPAND_FILL;browser.size_flags_stretch_ratio=1.0;browser.add_theme_constant_override("separation",8);composition.add_child(browser)
	pager=HBoxContainer.new();pager.name="Pages";pager.add_theme_constant_override("separation",8);browser.add_child(pager)
	previous=UI.verb(pager,"‹",func():change_page(-1));previous.name="Previous"
	count=UI.label(pager,"",14,T.INK_MUTED)
	next=UI.verb(pager,"›",func():change_page(1));next.name="Next"
	list=VBoxContainer.new();list.name="Events";list.add_theme_constant_override("separation",4);browser.add_child(list)
	reader=UI.sheet(composition,"SelectedTelling",16);reader.get_parent().size_flags_stretch_ratio=1.4
	resized.connect(_layout);redraw();_layout.call_deferred()

func _take(block:Dictionary)->void:
	model=block
	var given:Variant=block.get("view")
	view=given if given is Dictionary else {}
	for key:String in {"filter":"all","archive":false,"query":"","page":0,"selected":"","reader_open":false}:
		if not view.has(key):view[key]={"filter":"all","archive":false,"query":"","page":0,"selected":"","reader_open":false}[key]

func update_block(block:Dictionary)->bool:
	_take(block);redraw();return true

func set_archive(value:bool)->void:
	view.archive=value;view.reader_open=false;redraw()

func change_page(delta:int)->void:
	view.page=int(view.page)+delta;view.selected="";view.reader_open=false;redraw()

func _layout()->void:
	if not is_inside_tree() or composition==null:return
	composition.vertical=size.x<720
	_show_regions()

func _show_regions()->void:
	var single:=bool(view.archive) and composition.vertical
	browser.visible=not single or not bool(view.reader_open)
	reader.get_parent().visible=String(view.selected)!="" and (not single or bool(view.reader_open))
	var back:=reader.find_child("BackToResults",true,false) as Control
	if back!=null:back.visible=single

func select_entry(entry:Dictionary)->void:
	view.selected=entry_key(entry);view.reader_open=true;redraw()

static func entry_key(entry:Dictionary)->String:
	return "%s|%s|%s" % [entry.get("day",0),entry.get("group",""),entry.get("title","")]

func chosen()->Array:
	var out:Array=[]
	var query:=String(view.query).strip_edges().to_lower() if bool(view.archive) else ""
	for entry:Dictionary in model.get("entries",[]):
		if String(view.filter)!="all" and String(entry.get("group",""))!=String(view.filter):continue
		if query!="" and not (String(entry.get("title",""))+" "+String(entry.get("text",""))).to_lower().contains(query):continue
		out.append(entry)
	return out

func redraw()->void:
	var focused:=get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	var focus_name:=String(focused.name) if focused!=null and is_ancestor_of(focused) else ""
	var archive:=bool(view.archive)
	heading.text="World event archive" if archive else "Recently in the world"
	mode_button.text="Back to recent events" if archive else "Browse every event"
	search.visible=archive
	if search.text!=String(view.query):search.text=String(view.query)
	UI.clear(chips)
	var counts:Dictionary={"all":0}
	for entry:Dictionary in model.get("entries",[]):
		counts.all=int(counts.all)+1;counts[String(entry.get("group",""))]=int(counts.get(String(entry.get("group","")),0))+1
	for pair:Array in FILTERS:
		var key:=String(pair[0])
		var chip:=UI.chip(chips,"%s %d" % [pair[1],int(counts.get(key,0))],String(view.filter)==key,func():view.filter=key;view.page=0;view.selected="";view.reader_open=false;redraw());chip.name="Filter_"+key
	var entries:=chosen()
	view.page=clampi(int(view.page),0,maxi(0,(entries.size()-1)/PAGE))
	var start:=int(view.page)*PAGE if archive else 0
	var shown:=entries.slice(start,start+(PAGE if archive else RECENT))
	count.text="%d–%d of %d" % [start+1,start+shown.size(),entries.size()] if not shown.is_empty() else "0 matches"
	pager.visible=archive;previous.disabled=int(view.page)==0;next.disabled=start+shown.size()>=entries.size()
	UI.clear(list);UI.clear(reader)
	var selected:Dictionary={}
	for entry:Dictionary in shown:
		if entry_key(entry)==String(view.selected):selected=entry;break
	if selected.is_empty() and not shown.is_empty():selected=shown[0]
	view.selected=entry_key(selected) if not selected.is_empty() else ""
	for index in shown.size():_choice(shown[index],index)
	if shown.is_empty():
		if not archive or String(view.query)=="":UI.label(list,"No events in this category yet." if int(counts.all)>0 else "Nothing has passed between us and the world yet.",16,T.INK_MUTED,false,true)
	else:_telling(selected)
	_show_regions()
	if focus_name!="":
		var restore:=find_child(focus_name,true,false) as Control
		if restore!=null and restore.is_visible_in_tree():restore.grab_focus()

func _choice(entry:Dictionary,index:int)->void:
	var key:=entry_key(entry)
	var row:=UI.hot_row(list,"Event_"+str(index),select_entry.bind(entry),String(entry.get("title","")))
	if key==String(view.selected):
		var style:=T.flat(T.ACTIVE_BG,T.ACTION,0,T.RADIUS_CONTROL,8);style.border_color=T.ACTION;style.border_width_left=2;row.get_parent().add_theme_stylebox_override("panel",style)
		var panel:=row.get_parent() as PanelContainer
		panel.mouse_exited.connect(func():panel.add_theme_stylebox_override("panel",style))
		panel.focus_exited.connect(func():panel.add_theme_stylebox_override("panel",style))
	UI.icon(row,String(entry.get("icon","world")),_tint(String(entry.get("group",""))),18)
	var words:=VBoxContainer.new();words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;words.add_theme_constant_override("separation",2);row.add_child(words)
	UI.label(words,String(entry.get("title","")),16,T.INK,true,true)
	UI.label(words,_date(entry),14,T.INK_MUTED,false,true)

func _telling(entry:Dictionary)->void:
	var back:=UI.verb(reader,"Back to results",func():view.reader_open=false;_show_regions());back.name="BackToResults";back.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
	var head:=HFlowContainer.new();head.add_theme_constant_override("h_separation",12);reader.add_child(head)
	UI.label(head,_date(entry),14,T.INK_MUTED)
	if bool(entry.get("weighty",false)):UI.label(head,"Turning point",14,T.ACTION)
	if int(entry.get("count",1))>1:UI.label(head,"%d occurrences" % int(entry.count),14,T.INK_MUTED)
	UI.label(reader,String(entry.get("title","")),22,T.INK,true,true).name="SelectedTitle"
	var text:=String(entry.get("text",""))
	if text!="":UI.label(reader,text,16,T.BODY,false,true).name="SelectedText"
	var action:Variant=entry.get("on_open")
	if action is Callable and action.is_valid():
		var button:=UI.verb(reader,String(entry.get("action_label","Open related report")),action,"Open the original destination for this event");button.name="OpenReport";button.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN

static func _date(entry:Dictionary)->String:
	return "Year %d · %s" % [int(entry.get("day",0))/365+1,String(entry.get("season",""))]

static func _tint(group:String)->Color:
	return {"war":T.RED,"contact":T.TEAL,"scout":T.GOLD}.get(group,T.INK_MUTED)
