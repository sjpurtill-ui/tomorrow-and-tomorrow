extends Control
var heading:Label
var description:Label
var effects:Label
var question:Label
var history:Label
var status:Label
var choices:Array[Button]=[]
var ambition_buttons:Array[Button]=[]
var choice_notes:Array[Label]=[]
var automatic:CheckButton
var timer:=0.0
var opening:=false
func _ready()->void:
	opening=GameState.founding_focus==""
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background:=ColorRect.new(); background.color=Color("142831"); background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(background)
	var margin:=MarginContainer.new(); margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+edge,24)
	add_child(margin)
	var root:=VBoxContainer.new(); root.add_theme_constant_override("separation",12); margin.add_child(root)
	var top:=HBoxContainer.new(); root.add_child(top)
	var title:=_label(top,26); title.text="WHO ARE WE BECOMING?"; title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var people_button:=_button(top,"PEOPLE & LEGACIES",func():
		HistoricalFigures.ensure(); queue_free(); HistoricalFigures.open_chronicle(String(HistoricalFigures.people[0].id)))
	people_button.visible=not opening
	var network_button:=_button(top,"OUR CONNECTIONS · F9",func(): CommunityNetwork.open_network()); network_button.visible=not opening
	var close_button:=_button(top,"RETURN · F8",func(): queue_free()); close_button.visible=not opening
	var intro:=_label(root,16); intro.text="Choose a direction. Your people handle routine work. Visions can wait; nothing expires or demands an immediate answer."
	var ambitions:Container
	if opening:
		var grid:=GridContainer.new(); grid.columns=2; grid.add_theme_constant_override("h_separation",24); grid.add_theme_constant_override("v_separation",24); ambitions=grid
	else: ambitions=HFlowContainer.new()
	root.add_child(ambitions)
	for id:String in PeopleDirection.AMBITIONS:
		var card:=VBoxContainer.new(); card.size_flags_horizontal=Control.SIZE_EXPAND_FILL; ambitions.add_child(card)
		var button:=_button(card,PeopleDirection.AMBITIONS[id].name,func():
			var result:Dictionary=PeopleDirection.choose(id); status.text=String(result.get("error","A direction chosen. Let it unfold."))
			if opening and not result.has("error"): queue_free()
			else: _refresh())
		button.set_meta("ambition",id); ambition_buttons.append(button)
		if opening:
			var vision:=_label(card,19); vision.text=PeopleDirection.AMBITIONS[id].vision
			var consequence:=_label(card,15); consequence.text=PeopleDirection.AMBITIONS[id].effect; consequence.add_theme_color_override("font_color",Color("86cbbb"))
	heading=_label(root,23); heading.add_theme_color_override("font_color",Color("edce83"))
	description=_label(root,18)
	effects=_label(root,15); effects.add_theme_color_override("font_color",Color("86cbbb"))
	question=_label(root,18); question.size_flags_vertical=Control.SIZE_EXPAND_FILL
	var options:=HBoxContainer.new(); options.add_theme_constant_override("separation",18); root.add_child(options)
	for i in 2:
		var card:=VBoxContainer.new(); card.size_flags_horizontal=Control.SIZE_EXPAND_FILL; options.add_child(card)
		choices.append(_button(card,"",func():
			var result:Dictionary=PeopleDirection.decide(i); status.text=String(result.get("error","Your backing will help shape public values.")); _refresh()))
		choice_notes.append(_label(card,15))
	history=_label(root,15)
	automatic=CheckButton.new(); automatic.text="Community handles routine work"; automatic.toggled.connect(func(enabled:bool):
		PeopleDirection.automatic_work=enabled
		if enabled: PeopleDirection.work_baseline.clear(); PeopleDirection.work_day=int(GameState.elapsed_days)-30); root.add_child(automatic)
	status=_label(root,15)
	_refresh()
func _label(parent:Node,size:int)->Label:
	var l:=Label.new(); l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; l.add_theme_font_size_override("font_size",size); parent.add_child(l); return l
func _button(parent:Node,text:String,action:Callable)->Button:
	var b:=Button.new(); b.text=text; b.custom_minimum_size.y=36; b.pressed.connect(action); parent.add_child(b); return b
func _process(delta:float)->void:
	timer+=delta
	if timer>1: timer=0; _refresh()
func _refresh()->void:
	var state:=PeopleDirection
	var day:=int(GameState.elapsed_days)
	for element in [heading,description,effects,question,history]: element.visible=not opening
	automatic.set_pressed_no_signal(state.automatic_work)
	automatic.visible=false # Current settlement leaders own routine labor delegation.
	for button in ambition_buttons:
		button.disabled=String(button.get_meta("ambition"))==state.ambition or (state.chosen_day>=0 and day-state.chosen_day<365)
	if state.ambition=="":
		heading.text="A people with possibilities"
		description.text="What should your community become known for?"
		effects.text="One ambition at a time. You can reconsider after a year. Research still requires real labor, knowledge and evidence."
	else:
		var ambition:Dictionary=state.AMBITIONS[state.ambition]
		heading.text=ambition.name
		description.text=ambition.vision
		effects.text=ambition.effect
	var available:=state.ambition!="" and state.resolved<state.VISIONS.size() and day>=state.next_vision_day
	for choice in choices: choice.get_parent().visible=available
	if available:
		var vision:Dictionary=state.VISIONS[state.resolved]
		question.text="%s\n%s and %s offer competing perspectives.\n\n%s" % [vision.title,state.advocate(vision.role),state.advocate(vision.other),vision.question]
		for i in 2:
			choices[i].text=vision.options[i].label
			choice_notes[i].text=vision.options[i].meaning+" Public value shifts four points on its 0–100 scale."
	elif state.resolved>=state.VISIONS.size(): question.text="Your first traditions are taking shape. Your ambition continues to influence research and values as history unfolds."
	else: question.text="No decision needs your attention. Let your people pursue their direction; a new conversation becomes available after day %d. You can return whenever you wish." % state.next_vision_day
	history.text="RECENT DIRECTION"
	for entry:Dictionary in state.history.slice(0,2): history.text+="\nDay %d · %s" % [int(entry.day),entry.text]
