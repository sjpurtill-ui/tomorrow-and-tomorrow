extends VBoxContainer
const VisibleChoice=preload("res://scripts/hud/visible_choices.gd")
## One selected civilization, its reported capabilities, and its regard for us.
## Foreign readings come only from the existing intelligence/Standing estimates.
const T:=preload("res://scripts/hud/hud_tokens.gd")
const Model:=preload("res://scripts/hud/peoples_known_model.gd")
const Standing:=preload("res://scripts/standing.gd")
const TOWN_PAGE:=4
const GROUPS:=[
	["Learning","lore",["genius"]],
	["Making & prosperity","crafts,wealth,stores",["wealth","reach"]],
	["People & security","people,lives,fighters,walls,towns",["might","endurance","cunning"]],
	["Culture & society","",["splendor","order","persuasion"]]
]
var model:Dictionary={}
var view:Dictionary={}
var side:Array=[]
var own:Dictionary={}
var on_town:Callable
var on_speak:Callable
var counter:=""
var counter_tip:=""
var _labels:Dictionary={}
var _bars:Dictionary={}
var _profile:VBoxContainer
var _columns:BoxContainer
var _picker:VisibleChoice
var _search:LineEdit
var _counter:Label
var _page_shape:=""
var _town_rows:VBoxContainer

func setup(block:Dictionary)->void:
	name="PeoplesKnownBoard"
	size_flags_horizontal=Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation",12)
	_take(block)
	_build()
	resized.connect(_layout)
	get_viewport().size_changed.connect(func():_layout.call_deferred())

func _take(block:Dictionary)->void:
	model=block.get("model",{})
	var given:Variant=block.get("view",{})
	view=given if given is Dictionary else {}
	for pair:Array in [["sort","people"],["flip",false],["open",""],["selected",""],["query",""],["town_page",0]]:
		if not view.has(pair[0]):view[pair[0]]=pair[1]
	side=block.get("side",[]);own=block.get("own",{})
	on_town=block.get("on_town",Callable());on_speak=block.get("on_speak",Callable())
	counter=String(block.get("counter",""));counter_tip=String(block.get("counter_tip",""))
	if _row(String(view.selected)).is_empty():
		var old:=String(view.open)
		if not _row(old).is_empty():view.selected=old
		else:
			var ordered:=_rows()
			view.selected=String(ordered[0].civ_id) if not ordered.is_empty() else ""
			for candidate:Dictionary in ordered:
				if not bool(candidate.us):view.selected=String(candidate.civ_id);break

func update_block(block:Dictionary)->bool:
	_take(block)
	_refresh_picker()
	if _page_shape==_shape():_write()
	else:_build_profile()
	return true

func _rows()->Array:
	return Model.order(model.get("rows",[]),String(view.sort),bool(view.flip))

func _row(id:String)->Dictionary:
	for row:Dictionary in model.get("rows",[]):
		if String(row.civ_id)==id:return row
	return {}

func _selected()->Dictionary:return _row(String(view.selected))

func _side()->Dictionary:
	for item:Dictionary in side:
		if String(item.get("civ_id",""))==String(view.selected):return item
	return {}

func sort_by(column:String)->void:
	if String(view.sort)==column:view.flip=not bool(view.flip)
	else:view.sort=column;view.flip=false
	_refresh_picker()
	_write()

func select_people(id:String)->void:
	if _row(id).is_empty():return
	view.selected=id;view.open="";view.town_page=0
	_refresh_picker();_build_profile()

## Retained entry for callers that previously opened a people's towns.
func toggle(id:String)->void:
	if String(view.selected)!=id:view.selected=id;view.open=id
	else:view.open="" if String(view.open)==id else id
	view.town_page=0
	_refresh_picker();_build_profile()

func _build()->void:
	for child in get_children():remove_child(child);child.queue_free()
	_counter=_label(counter,14,T.INK_MUTED);_counter.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;add_child(_counter)
	var choose:=VBoxContainer.new();choose.name="CivilizationChooser";choose.add_theme_constant_override("separation",8);add_child(choose)
	_search=LineEdit.new();_search.name="FindPeople";_search.placeholder_text="Find a people";_search.text=String(view.query);_search.custom_minimum_size=Vector2(140,40);_search.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_search.size_flags_stretch_ratio=0.7;_search.add_theme_font_size_override("font_size",14);choose.add_child(_search)
	_search.text_changed.connect(func(text:String):view.query=text;_refresh_picker())
	_picker=VisibleChoice.new();_picker.searchable=false;_picker.name="SelectPeople";_picker.size_flags_horizontal=Control.SIZE_EXPAND_FILL;_picker.size_flags_stretch_ratio=1.3;_picker.custom_minimum_size.y=40;choose.add_child(_picker)
	_picker.fit_to_longest_item=false;_picker.clip_text=true;_picker.custom_minimum_size.x=120

	_picker.item_selected.connect(func(index:int):select_people(String(_picker.get_item_metadata(index))))
	choose.add_child(_label("ORDER BY · choose again to reverse",12,T.INK_MUTED))
	var order:=VisibleChoice.new();order.name="SortPeople";choose.add_child(order)
	for id:String in ["name","people","fighters","between","lore","wealth"]:
		order.add_item(String(_titles().get(id,id)))
		order.set_item_metadata(order.item_count-1,id)
		if id==String(view.sort):order.select(order.item_count-1)
	order.item_selected.connect(func(index:int):sort_by(String(order.get_item_metadata(index))))
	order.tooltip_text="Order the civilization selector by a known reading. Choose the same reading again to reverse it; unknown readings remain last."
	_profile=VBoxContainer.new();_profile.name="SelectedProfile";_profile.add_theme_constant_override("separation",10);add_child(_profile)
	_refresh_picker();_build_profile()

func _refresh_picker()->void:
	if not is_instance_valid(_picker):return
	_picker.clear()
	var matched_selected:=false
	var query:=String(view.query).strip_edges().to_lower()
	for row:Dictionary in _rows():
		if query!="" and not query in String(row.name).to_lower():continue
		_picker.add_item(String(row.name)+(" · us" if bool(row.us) else ""))
		var index:=_picker.item_count-1;_picker.set_item_metadata(index,String(row.civ_id))
		if String(row.civ_id)==String(view.selected):_picker.select(index);matched_selected=true
	if _picker.item_count==0:_picker.add_item("No matching peoples");_picker.set_item_disabled(0,true)
	elif not matched_selected:_picker.select(-1);_picker.text="Choose matching people"
	_picker.tooltip_text="Choose one civilization. Ordered by "+String(_titles().get(String(view.sort),view.sort))+(" (reversed)." if bool(view.flip) else ".")

func _shape()->String:
	var row:=_selected()
	return var_to_str([String(view.selected),bool(row.get("us",false)),String(view.open),int(view.town_page),on_speak.is_valid(),on_town.is_valid(),row.get("towns",[]),(side.map(func(p:Dictionary):return [p.get("civ_id",""),p.get("views",[]).size()])),own.keys()])

func _build_profile()->void:
	var focus:=get_viewport().gui_get_focus_owner()
	var focus_name:=String(focus.name) if focus!=null and is_ancestor_of(focus) else ""
	for child in _profile.get_children():_profile.remove_child(child);child.queue_free()
	_labels.clear();_bars.clear()
	var row:=_selected()
	if row.is_empty():return
	var header:=HFlowContainer.new();header.name="People_"+String(row.civ_id).validate_node_name();header.add_theme_constant_override("h_separation",14);header.add_theme_constant_override("v_separation",6);_profile.add_child(header)
	var title:=_label(String(row.name),26,T.INK,true);title.name="CivilizationName";header.add_child(title);_labels.name=title
	if bool(row.us):header.add_child(_label("our people",14,T.TEAL_TEXT))
	elif on_speak.is_valid():_button(header,"Talk",func():on_speak.call(String(view.selected)),true,"Talk")
	var fresh:=_label("",14,T.INK_MUTED);fresh.name="Freshness";fresh.size_flags_vertical=Control.SIZE_SHRINK_CENTER;header.add_child(fresh);_labels.fresh=fresh
	var between:=_label("",14,T.INK);between.name="BetweenUs";between.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;_profile.add_child(between);_labels.between=between
	# Independent stacks; their heights never force blank equal grid rows.
	_columns=BoxContainer.new();_columns.name="KnowledgeGroups";_columns.add_theme_constant_override("separation",24);_profile.add_child(_columns)
	var left:=VBoxContainer.new();left.size_flags_horizontal=Control.SIZE_EXPAND_FILL;left.add_theme_constant_override("separation",18);_columns.add_child(left)
	var right:=VBoxContainer.new();right.size_flags_horizontal=Control.SIZE_EXPAND_FILL;right.add_theme_constant_override("separation",18);_columns.add_child(right)
	for index in [0,1,2,3]:
		var spec:Array=GROUPS[index]
		var group:=_section(left if index<2 else right,String(spec[0]))
		for id:String in String(spec[1]).split(",",false):_fact(group,id)
		var arts:=HFlowContainer.new();arts.name="StrengthEstimates";arts.add_theme_constant_override("h_separation",18);arts.add_theme_constant_override("v_separation",5);group.add_child(arts)
		for id:String in spec[2]:
			var name_text:=id.capitalize()
			_reading(arts,"art_"+id,name_text,16)
		var unknown:=_label("",14,T.INK_MUTED);unknown.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;group.add_child(unknown);_labels["unknown_"+str(index)]=unknown
		if index==3:
			var note:=_label("Ways and customs have not been reported.",14,T.INK_MUTED);note.name="CultureEvidence";note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;group.add_child(note);_labels.culture=note
	var estimates:=_label("",14,T.INK_MUTED);estimates.name="EstimateContext";estimates.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;_profile.add_child(estimates);_labels.estimates=estimates
	if not bool(row.us):
		var regard:=VBoxContainer.new();regard.name="TheirRegard";regard.add_theme_constant_override("separation",6);_profile.add_child(regard)
		_profile.move_child(regard,_columns.get_index())
		var regard_head:=HFlowContainer.new();regard_head.add_theme_constant_override("h_separation",12);regard_head.add_theme_constant_override("v_separation",4);regard.add_child(regard_head)
		regard_head.add_child(_label("Their view of us",16,T.INK_MUTED))
		var summary:=_label("",18,T.INK,true);regard_head.add_child(summary);_labels.regard=summary
		_button(regard_head,"What this means",func():view["regard_details"]=not bool(view.get("regard_details",false));_write(),false,"RegardDetails")
		var views:=HFlowContainer.new();views.add_theme_constant_override("h_separation",18);views.add_theme_constant_override("v_separation",8);regard.add_child(views)
		for spec:Array in Standing.VIEWS:_reading(views,"view_"+String(spec[0]),String(spec[1]),16)
		for id:String in ["envy","contempt"]:_reading(views,"view_"+id,id.capitalize(),16)
		var note:=_label("",14,T.INK_MUTED);note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;regard.add_child(note);_labels.consequences=note
	var town_head:=HFlowContainer.new();town_head.add_theme_constant_override("h_separation",12);_profile.add_child(town_head)
	_button(town_head,"Hide towns" if String(view.open)==String(view.selected) else "Known towns",func():toggle(String(view.selected)),false,"ShowTowns")
	var contact:=_label("",14,T.INK_MUTED);contact.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;_profile.add_child(contact);_labels.contact=contact
	_town_rows=VBoxContainer.new();_town_rows.name="Towns_"+String(row.civ_id).validate_node_name();_town_rows.add_theme_constant_override("separation",10);_profile.add_child(_town_rows)
	_write();_write_towns();_page_shape=_shape();_layout.call_deferred()
	if focus_name!="":
		var next:=find_child(focus_name,true,false) as Control
		if next!=null:next.grab_focus()

func _section(parent:Node,title:String)->VBoxContainer:
	var box:=VBoxContainer.new();box.add_theme_constant_override("separation",6);parent.add_child(box)
	box.add_child(_label(title,20,T.INK,true))
	var rule:=ColorRect.new();rule.color=T.RULE;rule.custom_minimum_size.y=1;rule.mouse_filter=Control.MOUSE_FILTER_IGNORE;box.add_child(rule)
	return box

func _reading(parent:Node,key:String,caption:String,value_size:int)->void:
	var line:=HBoxContainer.new();line.name="Reading_"+key;line.add_theme_constant_override("separation",6);parent.add_child(line)
	line.add_child(_label(caption,14,T.INK_MUTED))
	var value:=_label("",value_size,T.INK,true);value.name="Value";line.add_child(value);_labels[key]=value

func _fact(parent:Node,id:String)->void:
	var line:=HFlowContainer.new();line.name="Cell_"+id;line.add_theme_constant_override("h_separation",8);line.add_theme_constant_override("v_separation",2);parent.add_child(line)
	var caption:=_label(String(_titles().get(id,id)),14,T.INK_MUTED);line.add_child(caption);_labels["caption_"+id]=caption
	var value:=_label("",18,T.INK,true);value.name="Value";line.add_child(value);_labels["cell_"+id]=value
	if id in ["people","fighters"]:
		var bar:=RangeBar.new();bar.name="Bar";bar.custom_minimum_size=Vector2(40,5);bar.size_flags_vertical=Control.SIZE_SHRINK_CENTER;line.add_child(bar);_bars[id]=bar

func _write()->void:
	var row:=_selected()
	if row.is_empty():return
	_counter.text=counter;_counter.tooltip_text=counter_tip;_counter.visible=counter!=""
	var us:=bool(row.us);var info:=_side()
	_put("name",String(row.name))
	var fresh:Dictionary=row.get("fresh",{})
	_put("fresh","Our own count · today" if us else "Reported "+String(fresh.get("text",""))+(" · "+String(fresh.source) if String(fresh.get("source",""))!="" else ""),String(fresh.get("tip","")))
	var between:Dictionary=(row.get("cells",{}) as Dictionary).get("between",{})
	var words:=PackedStringArray()
	for key:String in ["text","sub","stance"]:
		if String(between.get(key,""))!="":words.append(String(between[key]))
	var envoys:Dictionary=row.cells.get("envoys",{})
	if String(envoys.get("text",""))!="":words.append("Envoys: "+String(envoys.text))
	_put("between"," · ".join(words),String(between.get("tip","")));(_labels.between as Label).visible=not words.is_empty()
	for id:String in Model.RANKED:
		var cell:Dictionary=row.cells.get(id,{})
		var rank_tip:=String(cell.get("rank_tip",""))
		if id=="fighters" and not us:
			var est:=preload("res://scripts/enemy_strength.gd").fighters(String(row.civ_id))
			cell={"known":bool(est.get("known",false)),"text":String(est.get("range","")),"low":float(est.get("low",0)),"high":float(est.get("high",0)),"tip":String(est.get("tip",""))}
		var known:=bool(cell.get("known",false))
		_put("cell_"+id,String(cell.get("text","Unknown")) if known else "Unknown",String(Model.MEANINGS.get(id,""))+" "+String(cell.get("tip",""))+" "+rank_tip)
		if id=="lives":_put("caption_lives","Health" if String(cell.get("unit","main"))=="index" else String(_titles().get("lives","Lives")))
		if id=="lore":_put("caption_lore","Learning capacity" if String(cell.get("unit","main"))=="main" else "Learning")
		if _bars.has(id):
			var bar:RangeBar=_bars[id];bar.low=float(cell.get("low",0)) if known else -1;bar.high=float(cell.get("high",0)) if known else -1;bar.top=_top(id);bar.ours=_ours(id);bar.us=us;bar.queue_redraw()
	var strengths:Dictionary=own if us else info.get("theirs",{})
	for art:Array in Standing.STRENGTHS:
		var id:=String(art[0]);var reading:Dictionary=strengths.get(id,{})
		var known:=not reading.is_empty() and not bool(reading.get("unknown",false))
		var text:="Unknown"
		if known:text="%d%%" % roundi(float(reading.get("value",0))*100) if us or bool(reading.get("exact",false)) else "~%d%%" % roundi(float(reading.get("value",0))*100)
		var tip:=String(art[2]).capitalize()+". "
		if known:tip+=String(reading.get("why","Our own reading.")) if us else Standing.estimate_words(reading)+". "+String(info.get("known_words",""))
		else:tip+="We know too little of them to estimate this."
		_put("art_"+id,text,tip)
		(_labels["art_"+id] as Label).get_parent().visible=known
	for index in GROUPS.size():
		var unknown:=PackedStringArray()
		for id:String in GROUPS[index][2]:
			var reading:Dictionary=strengths.get(id,{})
			if reading.is_empty() or bool(reading.get("unknown",false)):unknown.append(id.capitalize())
		_put("unknown_"+str(index),", ".join(unknown)+": unknown" if not unknown.is_empty() else "")
		(_labels["unknown_"+str(index)] as Label).visible=not unknown.is_empty()
	_put("estimates","Strength readings compare us with the age." if us else "Strengths marked ~ are our watchers' estimates; point for their ranges.",String(info.get("known_words","")))
	_put("culture","Our ways and their effects are in Home · Culture." if us else "Ways and customs have not been reported.")
	if not us:
		var context:=PackedStringArray()
		for key:String in ["relation","ruler","strength","known_words"]:
			if String(info.get(key,""))!="":context.append(String(info[key]))
		var spies:Dictionary=info.get("spies",{})
		if String(spies.get("words",""))!="":context.append(String(spies.words))
		for memory:Dictionary in info.get("memories",[]):context.append(String(memory.get("text","")))
		_put("regard",String(info.get("headline","Their regard is not yet known.")),"\n".join(context))
		for spec:Array in Standing.VIEWS:
			var id:=String(spec[0]);var feeling:Dictionary={}
			for candidate:Dictionary in info.get("views",[]):
				if String(candidate.id)==id:feeling=candidate;break
			_put("view_"+id,"%d%%" % roundi(float(feeling.value)*100) if not feeling.is_empty() else "Unknown",String(feeling.get("means",spec[2]))+". "+String(feeling.get("why","")))
		for id:String in ["envy","contempt"]:_put("view_"+id,"%d%%" % roundi(float(info[id])*100) if info.has(id) else "Unknown",String(info.get(id+"_why","")))
		var consequences:=PackedStringArray()
		for effect:Dictionary in info.get("consequences",[]):consequences.append(String(effect.get("words","")))
		_put("consequences"," · ".join(consequences))
		(_labels.consequences as Label).visible=not consequences.is_empty() and bool(view.get("regard_details",false))
		var details:=find_child("RegardDetails",true,false) as Button
		if details!=null:details.visible=not consequences.is_empty();details.text="Hide meaning" if bool(view.get("regard_details",false)) else "What this means"
	var contacts:=PackedStringArray(row.get("contact",[]))
	var bands:Dictionary=row.get("bands",{})
	if not bands.is_empty():contacts.append("%d band%s seen in the field: %s" % [int(bands.count),"" if int(bands.count)==1 else "s",Model.count_text(float(bands.low),float(bands.high),false,false,String(model.get("stage","hearth")))])
	var unplaced:int=(model.get("unplaced",[]) as Array).size()
	if unplaced>0:contacts.append("%d towns of unidentified peoples" % unplaced)
	var unidentified:=PackedStringArray()
	for town:Dictionary in model.get("unplaced",[]):unidentified.append(String(town.get("name","Unidentified settlement")))
	_put("contact"," · ".join(contacts),"\n".join(unidentified));(_labels.contact as Label).visible=not contacts.is_empty()

func _write_towns()->void:
	for child in _town_rows.get_children():_town_rows.remove_child(child);child.queue_free()
	_town_rows.visible=String(view.open)==String(view.selected)
	if not _town_rows.visible:return
	var towns:Array=_selected().get("towns",[])
	if towns.is_empty():_town_rows.add_child(_label("No town has been seen yet.",14,T.INK_MUTED));return
	var page:=clampi(int(view.town_page),0,maxi(0,ceili(float(towns.size())/TOWN_PAGE)-1));view.town_page=page
	var controls:=HFlowContainer.new();controls.add_theme_constant_override("h_separation",10);_town_rows.add_child(controls)
	var previous:=_button(controls,"Previous",func():view.town_page=maxi(0,int(view.town_page)-1);_build_profile(),false,"PreviousTowns");previous.disabled=page==0
	controls.add_child(_label("%d–%d of %d known towns" % [page*TOWN_PAGE+1,mini((page+1)*TOWN_PAGE,towns.size()),towns.size()],14,T.INK_MUTED))
	var next:=_button(controls,"Next",func():view.town_page=int(view.town_page)+1;_build_profile(),false,"NextTowns");next.disabled=(page+1)*TOWN_PAGE>=towns.size()
	for town:Dictionary in towns.slice(page*TOWN_PAGE,(page+1)*TOWN_PAGE):
		var item:=VBoxContainer.new();item.name="Town_"+String(town.get("city_id",town.name)).validate_node_name();item.add_theme_constant_override("separation",4);_town_rows.add_child(item)
		var head:=HFlowContainer.new();head.add_theme_constant_override("h_separation",10);item.add_child(head);head.add_child(_label(String(town.name)+(" · home" if bool(town.get("home",false)) else ""),16,T.INK,true))
		if bool(town.get("open",false)) and on_town.is_valid():
			var city_id:=String(town.city_id);_button(head,"Read report",func():on_town.call(city_id),false,"Read_"+city_id.validate_node_name())
		var facts:=HFlowContainer.new();facts.add_theme_constant_override("h_separation",12);item.add_child(facts)
		for id:String in ["people","fighters","stores","walls"]:facts.add_child(_label(String(_titles().get(id,id))+" "+String(town.cells.get(id,"?")),14,T.INK))
		var fresh:Dictionary=town.get("fresh",{})
		var note:=_label("Held by "+String(town.get("held",""))+" · "+String(fresh.get("text",""))+" · "+String(fresh.get("source","")),14,T.INK_MUTED);note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;item.add_child(note)

func _put(key:String,text:String,tip:="")->void:
	var target:=_labels.get(key) as Label
	if target!=null:target.text=text;target.tooltip_text=tip

func _layout()->void:
	if not is_inside_tree() or not is_instance_valid(_columns):return
	var available:=minf(size.x,get_viewport_rect().size.x-global_position.x-24)
	_columns.vertical=available<460

func _titles()->Dictionary:return Model.titles(String(model.get("stage","hearth")))

func _top(id:String)->float:
	var top:=1.0
	for row:Dictionary in model.get("rows",[]):
		var cell:Dictionary=row.cells.get(id,{})
		if bool(cell.get("known",false)):top=maxf(top,float(cell.get("high",0)))
	return top

func _ours(id:String)->float:
	for row:Dictionary in model.get("rows",[]):
		if bool(row.us):
			var cell:Dictionary=row.cells.get(id,{})
			return float(cell.get("high",-1)) if bool(cell.get("known",false)) else -1
	return -1

static func _button(parent:Node,text:String,callback:Callable,primary:bool,node_name:String)->Button:
	var button:=Button.new();button.name=node_name;button.text=text;T.apply_button_style(button,primary);button.pressed.connect(callback);parent.add_child(button);return button

static func _label(text:String,size:int,color:Color,strong:=false)->Label:
	var label:=Label.new();label.text=text;label.add_theme_font_override("font",T.font("ui_strong" if strong else "ui"));label.add_theme_font_size_override("font_size",size);label.add_theme_color_override("font_color",color);return label

## A small uncertainty band; the gold tick is our own comparable count.
class RangeBar extends Control:
	var low:=-1.0
	var high:=-1.0
	var top:=1.0
	var ours:=-1.0
	var us:=false
	func _init()->void:mouse_filter=Control.MOUSE_FILTER_IGNORE
	func _draw()->void:
		draw_rect(Rect2(Vector2.ZERO,size),Color(T.INK,0.08))
		if high<0 or top<=0:return
		var ink:=T.TEAL if us else T.INK_MUTED
		var sure:=size.x*clampf(low/top,0,1);var most:=size.x*clampf(high/top,0,1)
		if most>sure:draw_rect(Rect2(sure,0,most-sure,size.y),Color(ink,0.28))
		draw_rect(Rect2(0,0,sure,size.y),ink)
		if not us and ours>=0:
			var x:=clampf(size.x*ours/top,1,size.x-1);draw_line(Vector2(x,-2),Vector2(x,size.y+2),T.GOLD,1)
