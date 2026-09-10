extends Control
signal close_requested
const T=preload("res://scripts/hud/hud_tokens.gd")
const V=preload("res://scripts/hud/city_report_visuals.gd")
var panel:PanelContainer
var slider:HSlider
var allocation:Label
var staffing:Label
var status:Label
var cost:Label
var parties:VBoxContainer
var focus_buttons:Dictionary={}
var presets:GridContainer
var timer:=0.0
var rendered:=""

func label(parent:Node,text:String,size:int=14,color:Color=T.BODY)->Label:
	var node:=T.make_label(text,size,color);node.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;parent.add_child(node);return node
func button(parent:Node,text:String,action:Callable)->Button:
	var node:=Button.new();node.text=text;node.custom_minimum_size.y=36;node.size_flags_horizontal=SIZE_EXPAND_FILL;node.add_theme_font_size_override("font_size",13)
	for state in ["normal","hover","pressed"]:
		var style:=T.flat(T.ACTIVE_BG if state=="pressed" else T.HOVER_BG if state=="hover" else T.TILE_BG,T.TEAL if state!="normal" else T.BORDER,1,5)
		style.content_margin_left=10;style.content_margin_right=10;style.content_margin_top=8;style.content_margin_bottom=8;node.add_theme_stylebox_override(state,style)
	node.pressed.connect(action);parent.add_child(node);return node
func _ready()->void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var dim:=ColorRect.new();dim.color=Color(0.015,.025,.03,.65);dim.set_anchors_and_offsets_preset(PRESET_FULL_RECT);add_child(dim)
	dim.gui_input.connect(func(event:InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:dim.accept_event();close_requested.emit())
	panel=PanelContainer.new();panel.name="ScoutDispatchCard";panel.set_meta("viewport_fit_hosted",true);add_child(panel)
	var style:=T.flat(T.DOCK_BG,T.BORDER_2,1,10);style.content_margin_left=20;style.content_margin_right=20;style.content_margin_top=16;style.content_margin_bottom=16;panel.add_theme_stylebox_override("panel",style)
	var shell:=VBoxContainer.new();shell.add_theme_constant_override("separation",10);panel.add_child(shell)
	var top:=HBoxContainer.new();shell.add_child(top)
	var title:=label(top,"SCOUTING",22,T.INK);title.autowrap_mode=TextServer.AUTOWRAP_OFF;title.size_flags_horizontal=SIZE_EXPAND_FILL
	var close:=button(top,"×",func():close_requested.emit());close.size_flags_horizontal=SIZE_SHRINK_END;close.custom_minimum_size.x=34;close.tooltip_text="Close · Escape or click the map"
	label(shell,"STANDING SCOUTING ORDERS",10,T.TEAL)
	var scroll:=ScrollContainer.new();scroll.size_flags_vertical=SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;shell.add_child(scroll)
	var body:=VBoxContainer.new();body.size_flags_horizontal=SIZE_EXPAND_FILL;body.add_theme_constant_override("separation",12);scroll.add_child(body)
	var commitment:=HBoxContainer.new();body.add_child(commitment)
	allocation=label(commitment,"",34,T.INK);allocation.custom_minimum_size.x=120
	staffing=label(commitment,"",14,T.TEXT_SOFT);staffing.size_flags_horizontal=SIZE_EXPAND_FILL
	slider=HSlider.new();slider.min_value=0;slider.max_value=10;slider.step=.5;slider.custom_minimum_size.y=26;slider.value=float(CivilizationSystem.scouting_staff.data.share)*100;body.add_child(slider)
	slider.value_changed.connect(func(value:float):CivilizationSystem.scouting_staff.set_policy(value/100.0,String(CivilizationSystem.scouting_staff.data.focus));refresh())
	presets=GridContainer.new();presets.columns=4;body.add_child(presets)
	for preset:Array in [["Off",0.0],["Light · 2%",2.0],["Regular · 5%",5.0],["Extensive · 10%",10.0]]:
		button(presets,preset[0],func():slider.value=preset[1])
	label(body,"FOCUS",11,T.MUTED)
	var focuses:=VBoxContainer.new();focuses.add_theme_constant_override("separation",6);body.add_child(focuses)
	for key:String in ["exploration","recruitment"]:
		var caption:="Exploration & discovery" if key=="exploration" else "Recruitment & influence"
		var choice:=button(focuses,caption,func():CivilizationSystem.scouting_staff.set_policy(slider.value/100.0,key);refresh())
		choice.icon=V.icon("logistics" if key=="exploration" else "population");choice.expand_icon=true;choice.add_theme_constant_override("icon_max_width",24);choice.alignment=HORIZONTAL_ALIGNMENT_LEFT;choice.toggle_mode=true;focus_buttons[key]=choice
		choice.tooltip_text="Prioritize uncharted ground, resource surveys and field discoveries." if key=="exploration" else "Seek people, invite newcomers and build goodwill through physical visits."
	status=label(body,"",13,T.TEAL);cost=label(body,"",12,T.TEXT_SOFT)
	label(body,"PARTIES IN THE FIELD",11,T.MUTED)
	parties=VBoxContainer.new();parties.add_theme_constant_override("separation",6);body.add_child(parties)
	label(body,"Leaders choose the routes and handle repeat departures. People away are unavailable for work at home. Knowledge returns with the people who actually traveled there.",12,T.MUTED)
	var footer:=HBoxContainer.new();shell.add_child(footer)
	button(footer,"City intelligence",func():close_requested.emit();CivilizationSystem.city_intelligence.open())
	button(footer,"Done",func():close_requested.emit())
	resized.connect(_layout);panel.minimum_size_changed.connect(func():_layout.call_deferred());_layout();refresh();_layout.call_deferred()
func _layout()->void:
	if not is_instance_valid(panel):return
	if is_instance_valid(presets):presets.columns=2 if size.x<550 else 4
	panel.size=Vector2(minf(600,size.x-24),minf(680,size.y-24));panel.position=(size-panel.size)*.5
func refresh()->void:
	if not is_instance_valid(slider):return
	var view:Dictionary=CivilizationSystem.scouting_staff.snapshot()
	allocation.text="%.1f%%" % (float(view.share)*100)
	staffing.text="of the population\nUp to %d scouts · %d away" % [int(view.target),int(view.away)]
	for key:String in focus_buttons:focus_buttons[key].set_pressed_no_signal(key==view.focus)
	status.text=String(view.status)
	cost.text="Food carried: %.1f per day across active parties. Staff keep seven days of civilian food at home." % float(view.daily_food)
	var keys:Array=[int(GameState.elapsed_days)]
	for mission:Dictionary in CivilizationSystem.scout_missions:keys.append([mission.get("mission_id",0),mission.get("personnel",0),mission.get("return_day",0),mission.get("route_status","")])
	var signature:=str(keys)
	if signature==rendered:return
	rendered=signature
	for child in parties.get_children():parties.remove_child(child);child.queue_free()
	if CivilizationSystem.scout_missions.is_empty():label(parties,"No parties away. Your allocation sets the next departure.",13,T.TEXT_SOFT)
	for mission:Dictionary in CivilizationSystem.scout_missions:
		var row:=HBoxContainer.new();parties.add_child(row)
		var people:=label(row,"%d" % int(mission.personnel),23,T.INK);people.custom_minimum_size.x=40
		var details:=VBoxContainer.new();details.size_flags_horizontal=SIZE_EXPAND_FILL;row.add_child(details)
		label(details,"Recruitment & influence" if mission.get("target_kind","")=="recruit_people" else "City observation" if mission.get("target_kind","")=="observe_city" else "Exploration & discovery",13,T.BODY)
		var remaining:=int(mission.return_day)-int(GameState.elapsed_days)
		label(details,"Expected in %dd · %d food carried" % [remaining,roundi(float(mission.provisions))] if remaining>=0 else "%dd overdue · awaiting their report" % -remaining,11,T.MUTED)
func _process(delta:float)->void:
	timer+=delta
	if timer>1:timer=0;refresh()
func _unhandled_input(event:InputEvent)->void:
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:get_viewport().set_input_as_handled();close_requested.emit()
