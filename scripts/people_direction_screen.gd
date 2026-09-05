extends Control
var opening:=false
var ambition_buttons:Array[Button]=[]
var pages:Array[Control]=[]
var summary:Label
var status:Label
var council:VBoxContainer
var traditions:VBoxContainer
var page_index:=0
var timer:=0.0
var grid:GridContainer
var selected_focus:=""

func _ready()->void:
	opening=GameState.founding_focus==""
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background:=ColorRect.new()
	background.color=Color("142831")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin:=MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+edge,20)
	add_child(margin)
	var root:=VBoxContainer.new()
	root.add_theme_constant_override("separation",12)
	margin.add_child(root)
	var top:=HBoxContainer.new()
	root.add_child(top)
	var title:=_label(top,"CHOOSE OUR CENTURY",24)
	title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_button(top,"RETURN · F8",func(): queue_free()).visible=not PeopleDirection.needs_century_choice()
	summary=_label(root,"",15)
	var tabs:=HBoxContainer.new()
	root.add_child(tabs)
	for index in 3:
		var tab_index:=index
		_button(tabs,["FOCUS","COUNCIL ADVICE","TRADITIONS"][index],func(): _show_page(tab_index))
	var body:=VBoxContainer.new()
	body.size_flags_vertical=Control.SIZE_EXPAND_FILL
	root.add_child(body)
	var focus_page:=VBoxContainer.new()
	body.add_child(focus_page); pages.append(focus_page)
	_label(focus_page,"Your choice—not the council's. Pick a focus, review its tradeoff, then confirm. No discoveries, supplies or wars are granted automatically.",14)
	grid=GridContainer.new(); grid.columns=4
	grid.add_theme_constant_override("h_separation",12); grid.add_theme_constant_override("v_separation",12)
	focus_page.add_child(grid)
	for id:String in PeopleDirection.AMBITIONS:
		var card:=VBoxContainer.new(); card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		grid.add_child(card)
		var button:=_button(card,PeopleDirection.AMBITIONS[id].name,func(): selected_focus=id; _refresh())
		button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size.y=56
		button.set_meta("ambition",id)
		ambition_buttons.append(button)
		_label(card,PeopleDirection.AMBITIONS[id].vision,13)
	var detail:=_label(focus_page,"",14)
	detail.name="SelectionDetail"
	var confirm:=_button(focus_page,"CONFIRM CENTURY FOCUS",func():
		var result:Dictionary=PeopleDirection.choose(selected_focus)
		status.text=String(result.get("error","Focus chosen. Resume time when ready."))
		if not result.has("error"): queue_free())
	confirm.name="ConfirmFocus"
	council=VBoxContainer.new(); body.add_child(council); pages.append(council)
	traditions=VBoxContainer.new(); body.add_child(traditions); pages.append(traditions)
	status=_label(root,"",14)
	_show_page(0)

func _label(parent:Node,text:String,font_size:int)->Label:
	var label:=Label.new(); label.text=text
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",font_size)
	parent.add_child(label)
	return label

func _button(parent:Node,text:String,action:Callable)->Button:
	var button:=Button.new(); button.text=text
	button.custom_minimum_size.y=34
	button.pressed.connect(action); parent.add_child(button)
	return button

func _show_page(index:int)->void:
	page_index=index
	for i in pages.size(): pages[i].visible=i==index
	if index==1: _council_page()
	if index==2: _traditions_page()
	_refresh()

func _process(delta:float)->void:
	timer+=delta
	if timer>=1.0:
		timer=0.0
		_refresh()

func _refresh()->void:
	var century:=PeopleDirection.century_at(int(GameState.elapsed_days))
	var pending:=PeopleDirection.needs_century_choice()
	summary.text="CENTURY %d · YEARS %d–%d · %s" % [century+1,century*100+1,(century+1)*100,"Awaiting your choice. Time remains paused." if pending else "Chosen: "+String(PeopleDirection.AMBITIONS[PeopleDirection.ambition].name)]
	grid.columns=4 if get_viewport_rect().size.x>=1000 else 2
	for button in ambition_buttons:
		button.disabled=not pending
		button.modulate=Color("edce83") if String(button.get_meta("ambition"))==selected_focus else Color.WHITE
	var detail:=pages[0].get_node("SelectionDetail") as Label
	detail.text=PeopleDirection.AMBITIONS[selected_focus].effect if selected_focus!="" else "Choose a focus above to review its effect. You may renew the same focus next century."
	(pages[0].get_node("ConfirmFocus") as Button).disabled=not pending or selected_focus==""

func _clear(parent:Node)->void:
	for child in parent.get_children(): parent.remove_child(child); child.queue_free()

func _council_page()->void:
	_clear(council)
	_label(council,"ADVICE, NOT ORDERS",20)
	_label(council,"Only serving officeholders speak here. More perspectives become available as your government grows. Unknown countries and hidden plans are not evidence.",14)
	var recommendations:=PeopleDirection.advisor_recommendations()
	if recommendations.is_empty():
		_label(council,"No appointed advisor is available yet. You can still choose any focus.",16)
	for advice in recommendations:
		_label(council,"%s · %s — %s" % [advice.name,advice.title,PeopleDirection.AMBITIONS[advice.focus].name],16)
		_label(council,advice.reason,14)

func _traditions_page()->void:
	_clear(traditions)
	_label(traditions,"TRADITIONS & CONTINUING VISIONS",20)
	var state:=PeopleDirection
	var day:=int(GameState.elapsed_days)
	if state.ambition!="" and state.resolved<state.VISIONS.size() and day>=state.next_vision_day:
		var vision:Dictionary=state.VISIONS[state.resolved]
		_label(traditions,vision.title,18)
		_label(traditions,"%s and %s offer perspectives. %s" % [state.advocate(vision.role),state.advocate(vision.other),vision.question],15)
		for index in 2:
			var choice_index:=index
			_button(traditions,vision.options[index].label,func():
				var result:Dictionary=state.decide(choice_index)
				status.text=String(result.get("error","Your backing shapes public values."))
				_traditions_page())
			_label(traditions,vision.options[index].meaning,14)
	else:
		_label(traditions,"Visions do not expire. The century focus does not replace choices already made in your traditions.",15)
	_label(traditions,"RECENT DIRECTION",16)
	for entry:Dictionary in state.history.slice(0,3):
		_label(traditions,"Day %d · %s" % [int(entry.day),entry.text],14)
	if not opening:
		_button(traditions,"PEOPLE & LEGACIES",func(): HistoricalFigures.ensure(); HistoricalFigures.open_chronicle(String(HistoricalFigures.people[0].id)))
		_button(traditions,"OUR CONNECTIONS",func(): CommunityNetwork.open_network())
