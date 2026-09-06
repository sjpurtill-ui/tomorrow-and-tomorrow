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
var choice_page:=0
var reviewing:=false
var focus_cards:Array[Control]=[]
var more_choices:Button
var choice_help:Label
var review_back:Button

const CARD_TITLES:=["Know the world","Build to last","Bring us together","Seek knowledge","Build strength","Create abundance","Care for people","Trade & connect"]
const CARD_TAGS:=["LOGISTICS · ECOLOGY","CRAFT · BUILDING","CULTURE · INSTITUTIONS","KNOWLEDGE · HEALTH","SECURITY · LOGISTICS","NUTRITION · ECOLOGY","HEALTH · DEMOGRAPHY","PRODUCTION · LOGISTICS"]
const CARD_COLORS:=["71bcb3","d8996a","d9b978","9ba7d6","cc7c68","b8c480","81c5ac","dbb57a"]
var title:Label
var layout:VBoxContainer

func _ready()->void:
	opening=GameState.founding_focus==""
	if not PeopleDirection.needs_century_choice():selected_focus=PeopleDirection.ambition;reviewing=true
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background:=ColorRect.new();background.color=Color("09191e");background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(background)
	var margin:=MarginContainer.new();margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+edge,18)
	add_child(margin)
	layout=VBoxContainer.new();layout.add_theme_constant_override("separation",9);margin.add_child(layout)
	var top:=HBoxContainer.new();layout.add_child(top)
	title=_label(top,"YOUR PEOPLE’S STORY BEGINS",30);title.size_flags_horizontal=SIZE_EXPAND_FILL
	_button(top,"RETURN · F8",func():queue_free()).visible=not PeopleDirection.needs_century_choice()
	summary=_label(layout,"",14)
	var tabs:=HBoxContainer.new();layout.add_child(tabs)
	for index in 3:
		var tab_index:=index
		_button(tabs,["OUR DIRECTION","COUNCIL","TRADITIONS"][index],func():_show_page(tab_index))
	var body:=VBoxContainer.new();body.size_flags_vertical=SIZE_EXPAND_FILL;layout.add_child(body)
	var focus_page:=VBoxContainer.new();focus_page.size_flags_vertical=SIZE_EXPAND_FILL;body.add_child(focus_page);pages.append(focus_page)
	grid=GridContainer.new();grid.columns=4;grid.size_flags_vertical=SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation",10);grid.add_theme_constant_override("v_separation",10);focus_page.add_child(grid)
	var index:=0
	for id:String in PeopleDirection.AMBITIONS:
		var card:=preload("res://scripts/ambition_art_card.gd").new()
		card.art_index=index;card.caption=CARD_TITLES[index];card.subtitle=CARD_TAGS[index];card.accent=Color(CARD_COLORS[index]);card.size_flags_horizontal=SIZE_EXPAND_FILL;card.size_flags_vertical=SIZE_EXPAND_FILL
		card.set_meta("ambition",id);card.tooltip_text=String(PeopleDirection.AMBITIONS[id].vision)
		card.pressed.connect(func():selected_focus=id;reviewing=true;_refresh())
		grid.add_child(card);ambition_buttons.append(card);focus_cards.append(card);index+=1
	choice_help=_label(focus_page,"",14)
	var detail:=_label(focus_page,"",16);detail.name="SelectionDetail";detail.custom_minimum_size.y=65
	var confirm:=_button(focus_page,"CHOOSE A DIRECTION ABOVE",func():
		var result:Dictionary=PeopleDirection.choose(selected_focus)
		status.text=String(result.get("error","Focus chosen. Resume time when ready."))
		if not result.has("error"):queue_free())
	confirm.name="ConfirmFocus";confirm.custom_minimum_size.y=43
	var commit_style:=StyleBoxFlat.new();commit_style.bg_color=Color("c7a55f");commit_style.set_corner_radius_all(3);confirm.add_theme_stylebox_override("normal",commit_style);confirm.add_theme_color_override("font_color",Color("112126"));confirm.add_theme_font_size_override("font_size",16)
	council=VBoxContainer.new();body.add_child(council);pages.append(council)
	traditions=VBoxContainer.new();body.add_child(traditions);pages.append(traditions)
	status=_label(layout,"",13);status.visible=false
	resized.connect(_refresh);_show_page(0)
	print("DIRECTION_SCREEN_READY: day=",GameState.elapsed_days,"; opening=",opening,"; settlement=",GameState.settlement_name,"; seed=",GameState.world_seed)
	_capture_opening.call_deferred()

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
	if not is_instance_valid(grid):return
	var century:=PeopleDirection.century_at(int(GameState.elapsed_days))
	var pending:=PeopleDirection.needs_century_choice()
	title.text="YOUR PEOPLE’S STORY BEGINS" if opening else "THE NEXT GENERATIONS."
	title.add_theme_font_size_override("font_size",24 if size.x<1000 else 32)
	summary.text="Give your people a purpose for the next 100 years. Their leaders handle the daily work." if opening else "Years %d–%d · A shared direction for the coming century."%[century*100+1,(century+1)*100]
	grid.columns=4
	for card in ambition_buttons:
		card.disabled=not pending;card.select(String(card.get_meta("ambition"))==selected_focus)
	choice_help.text="Choose the future you want to encourage. Time is paused." if selected_focus=="" else String(PeopleDirection.AMBITIONS[selected_focus].vision)
	var detail:=pages[0].get_node("SelectionDetail") as Label
	if selected_focus=="":
		detail.text="Each direction accelerates two kinds of learning and gradually shapes a social value.\nChoose a card to see the exact benefit and tradeoff."
	else:
		detail.text=String(PeopleDirection.AMBITIONS[selected_focus].effect)+"\nA direction for 100 years; progress still comes from your people's work and discoveries."
	detail.add_theme_font_size_override("font_size",14 if size.y<700 else 16)
	var confirm:=pages[0].get_node("ConfirmFocus") as Button
	confirm.disabled=not pending or selected_focus==""
	confirm.text="CHOOSE A DIRECTION ABOVE" if selected_focus=="" else ("BEGIN · " if opening else "COMMIT · ")+CARD_TITLES[PeopleDirection.AMBITIONS.keys().find(selected_focus)].to_upper()

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

func _capture_opening()->void:
	if "--capture-opening" not in OS.get_cmdline_user_args() or get_tree().root.has_meta("opening_captured"):return
	get_tree().root.set_meta("opening_captured",true)
	for frame in 8:await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var result:=get_viewport().get_texture().get_image().save_png("res://artifacts/player-opening.png")
	print("OPENING_CAPTURE: ",result,"; day=",GameState.elapsed_days,"; opening=",opening)
