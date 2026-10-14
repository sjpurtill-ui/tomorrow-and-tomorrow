extends "res://scripts/hud/settlement_overview.gd"
## Home keeps related facts together, with independent section heights.
## The provider owns all numbers and actions; this file only composes them.

var _reading_refs:Dictionary={}
var _sections:Array[VBoxContainer]=[]
var _lanes:Array[VBoxContainer]=[]
var _facts:HBoxContainer
var _lane_count:=0

func setup(block:Dictionary)->void:
	super.setup(block)
	add_theme_constant_override("separation",16)
	get_viewport().size_changed.connect(func():_layout.call_deferred())

func _leader(block:Dictionary,parent:Node)->void:
	_reading_refs.clear()
	var leader:Dictionary=block.get("leader",{})
	var group:=VBoxContainer.new();group.name="Leader";group.add_theme_constant_override("separation",10);group.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(group)
	var row:=HFlowContainer.new();row.add_theme_constant_override("h_separation",16);row.add_theme_constant_override("v_separation",8);group.add_child(row)
	var identity:=HBoxContainer.new();identity.add_theme_constant_override("separation",12);row.add_child(identity)
	if not leader.is_empty():identity.add_child(Portrait.picture(leader,38,46))
	var named:=VBoxContainer.new();named.add_theme_constant_override("separation",2);named.size_flags_vertical=Control.SIZE_SHRINK_CENTER;identity.add_child(named)
	var who:=T.make_label(String(leader.get("name","No leader yet")),22,T.INK);who.add_theme_font_override("font",T.font("ui_strong"));named.add_child(who)
	var office:=T.make_label(_office_words(leader),14,T.MUTED);named.add_child(office);_page_refs.office=office
	who.tooltip_text=String(block.get("direction",""))+"\n"+String(block.get("direction_tip",""));who.mouse_filter=Control.MOUSE_FILTER_PASS;_page_refs.direction=who
	var first:=String(leader.get("name","")).get_slice(" ",0)
	var talk:=_button(row,"Talk with %s" % first if not first.is_empty() else "Open the court",block.get("on_leader"),"Call the leader to the court to talk, give orders or replace them")
	T.apply_button_style(talk,true);talk.name="TalkWithLeader";talk.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	var controls:Container=HFlowContainer.new() if bool(block.get("ruler_sets_work",false)) else VBoxContainer.new();controls.name="LeaderControls";controls.add_theme_constant_override("h_separation",8);controls.add_theme_constant_override("v_separation",6);group.add_child(controls)

func _section(title:String)->VBoxContainer:
	var section:=VBoxContainer.new();section.name="Group_"+title.to_pascal_case();section.add_theme_constant_override("separation",4);section.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var heading:=T.make_label(title,20,T.INK);heading.add_theme_font_override("font",T.font("ui_strong"));section.add_child(heading)
	_sections.append(section)
	return section

func _groups(groups:Array,_legend:Array,_own_name:String)->void:
	_rule(self)
	_facts=HBoxContainer.new();_facts.name="Figures";_facts.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN;_facts.add_theme_constant_override("separation",28);add_child(_facts)
	for index in 3:
		var lane:=VBoxContainer.new();lane.name="Lane%d"%index;lane.size_flags_horizontal=Control.SIZE_EXPAND_FILL;lane.add_theme_constant_override("separation",16);_facts.add_child(lane);_lanes.append(lane)
	var people:=_section("People")
	var defense:=_section("Defense")
	var town:=_section("Homes and works")
	var readings:Array=data.get("readings",[])
	if readings.size()>=4:
		for index in [1,2,0]:_home_reading(people,readings[index])
		_home_reading(defense,readings[3])
	# Keep refresh references in provider order even when sections move.
	for group:Dictionary in groups:
		for row:Dictionary in group.rows:
			var target:=people if String(group.title).to_lower().contains("people") else (defense if String(row.key) in ["garrison","fortification"] else town)
			target.add_child(_row(row))
	_layout()

func _interactive(panel:PanelContainer,action:Variant)->void:
	var idle:=T.flat(Color.TRANSPARENT,Color.TRANSPARENT,0,3)
	idle.content_margin_left=4;idle.content_margin_right=4;idle.content_margin_top=4;idle.content_margin_bottom=4
	var lit:StyleBoxFlat=idle.duplicate();lit.bg_color=T.HOVER_BG
	panel.add_theme_stylebox_override("panel",idle)
	panel.mouse_filter=Control.MOUSE_FILTER_STOP
	if action is Callable and (action as Callable).is_valid():
		panel.focus_mode=Control.FOCUS_ALL;panel.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
		panel.gui_input.connect(func(event:InputEvent)->void:
			var mouse:=event as InputEventMouseButton
			if (mouse and mouse.pressed and mouse.button_index==MOUSE_BUTTON_LEFT) or event.is_action_pressed("ui_accept"):
				panel.accept_event();(action as Callable).call())
		panel.mouse_entered.connect(func():panel.add_theme_stylebox_override("panel",lit))
		panel.focus_entered.connect(func():panel.add_theme_stylebox_override("panel",lit))
		panel.mouse_exited.connect(func():panel.add_theme_stylebox_override("panel",idle))
		panel.focus_exited.connect(func():panel.add_theme_stylebox_override("panel",idle))

func _home_reading(parent:Node,reading:Dictionary)->void:
	var panel:=PanelContainer.new();panel.name="Reading_"+String(reading.label);parent.add_child(panel);_interactive(panel,reading.get("on_press"));panel.tooltip_text=String(reading.get("tip",""))
	var stack:=VBoxContainer.new();stack.add_theme_constant_override("separation",2);stack.mouse_filter=Control.MOUSE_FILTER_IGNORE;panel.add_child(stack)
	var row:=HFlowContainer.new();row.add_theme_constant_override("h_separation",8);row.add_theme_constant_override("v_separation",0);row.mouse_filter=Control.MOUSE_FILTER_IGNORE;stack.add_child(row)
	var value:=T.make_label(String(reading.value),18,T.INK);value.name="Value";value.add_theme_font_override("font",T.font("ui_strong"));value.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(value)
	var label:=T.make_label(T.sentence_case(String(reading.label)),14,T.MUTED);label.size_flags_vertical=Control.SIZE_SHRINK_CENTER;label.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(label)
	row.move_child(label,0)
	var note:=T.make_label(String(reading.get("delta","")),14,T.MUTED);note.size_flags_vertical=Control.SIZE_SHRINK_CENTER;note.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(note)
	if reading.has("meter"):
		var bar:=ProgressBar.new();bar.name="Bar";bar.custom_minimum_size=Vector2(42,3);bar.size_flags_vertical=Control.SIZE_SHRINK_CENTER;bar.show_percentage=false;bar.max_value=1.0;bar.value=clampf(float(reading.meter),0,1);bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
		bar.add_theme_stylebox_override("background",T.flat(T.TRACK));bar.add_theme_stylebox_override("fill",T.flat(T.TEAL));row.add_child(bar)
	_reading_refs[String(reading.label)]={"row":panel,"note":note}

func update_block(block:Dictionary)->bool:
	if not super.update_block(block):return false
	for reading:Dictionary in block.get("readings",[]):
		if not _reading_refs.has(String(reading.label)):continue
		var refs:Dictionary=_reading_refs[String(reading.label)]
		_put(refs.row.find_child("Value",true,false),String(reading.value));_put(refs.note,String(reading.get("delta","")))
		refs.row.tooltip_text=String(reading.get("tip",""))
		var bar:=refs.row.find_child("Bar",true,false) as ProgressBar
		if bar:bar.value=clampf(float(reading.get("meter",0.0)),0.0,1.0)
	return true

func _row(row:Dictionary)->Control:
	var panel:=PanelContainer.new();panel.name="Row_"+String(row.key);_interactive(panel,row.get("on_open"))
	var line:=HFlowContainer.new();line.add_theme_constant_override("h_separation",6);line.add_theme_constant_override("v_separation",0);line.mouse_filter=Control.MOUSE_FILTER_IGNORE;panel.add_child(line)
	var label:=T.make_label("",14,T.MUTED);label.name="Name";label.mouse_filter=Control.MOUSE_FILTER_IGNORE;label.size_flags_vertical=Control.SIZE_SHRINK_CENTER;line.add_child(label)
	var value:=T.make_label("",16,T.INK);value.name="Value";value.add_theme_font_override("font",T.font("ui_strong"));value.mouse_filter=Control.MOUSE_FILTER_IGNORE;line.add_child(value)
	var refs:={"panel":panel,"name":label,"value":value,"bar":null,"note":null}
	_fill_row(refs,row);(_page_refs.rows as Array).append(refs)
	return panel

func _fill_row(refs:Dictionary,row:Dictionary)->void:
	super._fill_row(refs,row)
	var more:PackedStringArray=[]
	if String(row.get("note",""))!="":more.append(String(row.note))
	for mark:Dictionary in row.get("marks",[]):more.append("%s · %s · seen %s" % [String(mark.name),String(mark.words),String(mark.seen)])
	if not more.is_empty():(refs.panel as Control).tooltip_text=String(row.get("tip",""))+"\n"+"\n".join(more)
	var tone:=String(row.get("note_tone",""));(refs.value as Label).add_theme_color_override("font_color",tone_color(tone) if tone in ["bad","warn"] else T.INK)

func _places(places:Dictionary)->void:
	_rule(self)
	var view:=_places_view(places);view.name="Places"
	_page_refs.places=view;_page_refs.places_print=_places_print(places)

func _places_view(places:Dictionary)->Control:
	var list:=VBoxContainer.new();list.add_theme_constant_override("separation",6);add_child(list)
	var heading:=T.make_label(String(places.get("heading","Where our people live")),20,T.INK);heading.name="PlacesHeading";heading.add_theme_font_override("font",T.font("ui_strong"));list.add_child(heading)
	for item:Dictionary in places.get("rows",[]):
		var row:=HFlowContainer.new();row.add_theme_constant_override("h_separation",10);row.add_theme_constant_override("v_separation",4);row.tooltip_text=String(item.get("tip",""));row.mouse_filter=Control.MOUSE_FILTER_PASS;list.add_child(row)
		var cells:Dictionary=item.get("cells",{})
		for key in ["place","people","where"]:
			var text:=String(cells.get(key,""))
			if text.is_empty():continue
			if key=="people":text+=" people"
			var label:=T.make_label(text,16 if key=="place" else 14,T.INK if key=="place" else T.BODY);label.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(label)
			if key=="place":label.add_theme_font_override("font",T.font("ui_strong"))
		if item.has("bar"):
			var meter:=ProgressBar.new();meter.custom_minimum_size=Vector2(44,3);meter.size_flags_vertical=Control.SIZE_SHRINK_CENTER;meter.show_percentage=false;meter.value=float(item.bar.get("value",0))*100
			meter.add_theme_stylebox_override("background",T.flat(T.TRACK));meter.add_theme_stylebox_override("fill",T.flat(T.TEAL));row.add_child(meter)
		var tag:Dictionary=item.get("tag",{})
		if not String(tag.get("text","")).is_empty():
			var note:=T.make_label(String(tag.text),14,tone_color(String(tag.get("tone",""))));note.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(note)
		var button:Dictionary=item.get("button",{})
		if not button.is_empty():
			var action:=OwnBlocks.verb(String(button.get("label","")),button.get("on_press"),String(button.get("tip","")),bool(button.get("disabled",false)));row.add_child(action)
	return list

func _layout()->void:
	if spread:spread.vertical=false
	if not _facts:return
	# A child's old minimum must not hold the page wider than a resized dock.
	var available:=minf(size.x,get_viewport_rect().size.x-global_position.x-24)
	var ancestor:=get_parent()
	while ancestor:
		if ancestor is ScrollContainer:available=minf(available,(ancestor as Control).size.x-32)
		ancestor=ancestor.get_parent()
	var count:=3 if available>=960 else (2 if available>=620 else 1)
	for lane:VBoxContainer in _lanes:lane.custom_minimum_size.x=minf(340.0,maxf(1.0,(available-28*(count-1))/count))
	if count==_lane_count:return
	_lane_count=count
	for index in _lanes.size():_lanes[index].visible=index<count
	for index in _sections.size():
		var section:=_sections[index]
		var lane:=index if count==3 else (1 if count==2 and index==2 else 0)
		if section.get_parent():section.reparent(_lanes[lane])
		else:_lanes[lane].add_child(section)
