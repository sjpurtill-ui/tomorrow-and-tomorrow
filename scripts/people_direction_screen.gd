extends Control
## Our course and our character: the century choice and the inheritance it
## leaves. Paper and ink. Advice about the choice is heard in the court.
const T:=preload("res://scripts/hud/hud_tokens.gd")
const P:=preload("res://scripts/hud/paper_sheet.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")
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

const CARD_TITLES:=["Know the world","Build to last","Bring us together","Seek knowledge","Build strength","Create abundance","Care for people","Trade and connect","Found new horizons","Rule and extract","Chosen people","Entrench a dynasty","Rule through fear","One official truth"]
## Plain words for what each course favours; true in every era.
const CARD_TAGS:=["Travel and the land","Craft and building","Customs and belonging","Learning and healing","Defence and supply","Food and the land","Health and families","Making and carrying goods","New homes and families","Force and order","Kin and defence","Rank and building","Force and order","Belief and order"]
const CARD_COLORS:=["71bcb3","d8996a","d9b978","9ba7d6","cc7c68","b8c480","81c5ac","dbb57a","c7ac69","b27256","ac9a7b","bd985e","a46658","95859f"]
var title:Label
var layout:VBoxContainer

func _ready()->void:
	theme=T.control_theme()
	opening=WorldSimulation.state.founding_focus==""
	if not WorldSimulation.direction.needs_century_choice():selected_focus=WorldSimulation.direction.ambition;reviewing=true
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background:=ColorRect.new();background.color=T.PAPER;background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(background)
	var margin:=MarginContainer.new();margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+edge,20)
	add_child(margin)
	layout=VBoxContainer.new();layout.add_theme_constant_override("separation",10);margin.add_child(layout)
	var top:=HBoxContainer.new();top.add_theme_constant_override("separation",12);layout.add_child(top)
	title=_label(top,"A people takes shape","title");title.size_flags_horizontal=SIZE_EXPAND_FILL
	var close:=_button(top,"Close",func():queue_free());close.name="Close";close.visible=not WorldSimulation.direction.needs_century_choice()
	summary=_label(layout,"","body")
	var tabs:=HBoxContainer.new();tabs.add_theme_constant_override("separation",8);layout.add_child(tabs)
	for index in 2:
		var tab_index:=index
		_button(tabs,["Our course","Our character"][index],func():_show_page(tab_index))
	P.rule(layout)
	var body:=VBoxContainer.new();body.size_flags_vertical=SIZE_EXPAND_FILL;layout.add_child(body)
	var focus_page:=VBoxContainer.new();focus_page.size_flags_vertical=SIZE_EXPAND_FILL;focus_page.add_theme_constant_override("separation",8);body.add_child(focus_page);pages.append(focus_page)
	var cards_scroll:=ScrollContainer.new();cards_scroll.size_flags_vertical=SIZE_EXPAND_FILL;focus_page.add_child(cards_scroll)
	grid=GridContainer.new();grid.columns=4;grid.size_flags_vertical=SIZE_EXPAND_FILL;grid.size_flags_horizontal=SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation",10);grid.add_theme_constant_override("v_separation",10);cards_scroll.add_child(grid)
	var index:=0
	for id:String in PeopleDirection.AMBITIONS:
		var card:=preload("res://scripts/ambition_art_card.gd").new()
		card.custom_minimum_size.y=175;card.art_index=index;card.caption=CARD_TITLES[index];card.subtitle=CARD_TAGS[index];card.accent=Color(CARD_COLORS[index]);card.size_flags_horizontal=SIZE_EXPAND_FILL;card.size_flags_vertical=SIZE_EXPAND_FILL
		if preload("res://scripts/hud/early_civ_art.gd").active():card.custom_minimum_size.y=260
		card.set_meta("ambition",id);card.tooltip_text=String(PeopleDirection.AMBITIONS[id].vision)
		card.pressed.connect(func():selected_focus=id;reviewing=true;_refresh())
		grid.add_child(card);ambition_buttons.append(card);focus_cards.append(card);index+=1
	choice_help=_label(focus_page,"","small")
	var detail:=_label(focus_page,"","body",T.INK);detail.name="SelectionDetail";detail.custom_minimum_size.y=24
	var confirm:=P.button(focus_page,"Choose a course above",Callable(),true)
	confirm.pressed.connect(func():
		var result:Dictionary=WorldSimulation.direction.choose(selected_focus)
		status.text=String(result.get("error","Course chosen. Resume time when ready."))
		if not result.has("error"):queue_free())
	confirm.name="ConfirmFocus";confirm.custom_minimum_size.y=44;T.text(confirm,"body",T.INK)
	council=null
	var traditions_scroll:=ScrollContainer.new();traditions_scroll.size_flags_vertical=SIZE_EXPAND_FILL;traditions_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;body.add_child(traditions_scroll);pages.append(traditions_scroll)
	traditions=VBoxContainer.new();traditions.size_flags_horizontal=SIZE_EXPAND_FILL;traditions_scroll.add_child(traditions)
	status=_label(layout,"","small");status.visible=false
	resized.connect(_refresh);_show_page(0 if WorldSimulation.direction.needs_century_choice() else 1)
	print("DIRECTION_SCREEN_READY: day=",WorldSimulation.state.elapsed_days,"; opening=",opening,"; settlement=",WorldSimulation.state.settlement_name,"; seed=",WorldSimulation.state.world_seed)
	_capture_opening.call_deferred()

## Roles: "title", "voice", "value", "body", "small", "kicker" (12 px floor).
func _label(parent:Node,text:String,role:String,color:Color=Color(0,0,0,0))->Label:
	return P.label(parent,text,role,color)

func _button(parent:Node,text:String,action:Callable)->Button:
	var button:=P.button(parent,text,action)
	button.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
	button.custom_minimum_size=Vector2(120,36)
	return button

func _show_page(index:int)->void:
	page_index=clampi(index,0,pages.size()-1)
	for i in pages.size(): pages[i].visible=i==page_index
	if page_index==1: _traditions_page()
	_refresh()

func _process(delta:float)->void:
	timer+=delta
	if timer>=1.0:
		timer=0.0
		_refresh()

func _refresh()->void:
	if not is_instance_valid(grid):return
	var century:=WorldSimulation.direction.century_at(int(WorldSimulation.state.elapsed_days))
	var pending:=WorldSimulation.direction.needs_century_choice()
	title.text="A people takes shape" if opening else "The character of a people"
	summary.text="Choose what your people will strive for first." if opening else ("Years %d to %d of our story. Choose the course for this century." if pending else "Years %d to %d of our story.") % [century*100+1,(century+1)*100]
	grid.columns=2 if size.x<1000 else 4
	for card in ambition_buttons:
		card.disabled=not pending;card.select(String(card.get_meta("ambition"))==selected_focus)
	choice_help.visible=false
	var detail:=pages[0].get_node("SelectionDetail") as Label
	if selected_focus=="":detail.text="Pick a card to see what it would change. Every choice leaves a mark on later generations."
	else:
		var ambition:Dictionary=PeopleDirection.AMBITIONS[selected_focus]
		detail.text="%s %s" % [String(ambition.vision),String(ambition.get("effect",""))]
		detail.tooltip_text=""
	var confirm:=pages[0].get_node("ConfirmFocus") as Button
	confirm.disabled=not pending or selected_focus==""
	var chosen_title:String=CARD_TITLES[PeopleDirection.AMBITIONS.keys().find(selected_focus)] if selected_focus!="" else ""
	if selected_focus=="":confirm.text="Choose a course above"
	elif not pending:confirm.text="This century's course is set: %s" % chosen_title
	else:confirm.text=("Begin: %s" if opening else "Commit to this course: %s") % chosen_title

func _clear(parent:Node)->void:
	for child in parent.get_children(): parent.remove_child(child); child.queue_free()

const VALUE_COLORS:=[Color("8b9b76"),Color("ba945b"),Color("688b91"),Color("ac7564")]

func _art(parent:Node,index:int,height:float)->TextureRect:
	var rect:=TextureRect.new();rect.custom_minimum_size.y=height;rect.size_flags_horizontal=SIZE_EXPAND_FILL
	rect.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;rect.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	rect.texture=preload("res://scripts/hud/ambition_art.gd").texture(index)
	if preload("res://scripts/hud/early_civ_art.gd").active():rect.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	parent.add_child(rect);return rect

func _box(parent:Node)->VBoxContainer:
	var content:=P.card(parent)
	content.add_theme_constant_override("separation",10)
	(content.get_parent() as PanelContainer).add_theme_stylebox_override("panel",P.card_style(Color(0,0,0,0),16))
	return content

func _plain(id:String)->String:
	return id.replace("_"," ").capitalize()

func _traditions_page()->void:
	_clear(traditions)
	traditions.add_theme_constant_override("separation",14)
	var state=WorldSimulation.direction
	var spread:=BoxContainer.new();spread.vertical=size.x<900;spread.add_theme_constant_override("separation",18);traditions.add_child(spread)
	var portrait:=_box(spread);portrait.get_parent().size_flags_stretch_ratio=.85
	var focus:=String(state.ambition)
	var focus_index:=maxi(0,PeopleDirection.AMBITIONS.keys().find(focus))
	_art(portrait,focus_index,265)
	P.kicker(portrait,"Our present course")
	_label(portrait,CARD_TITLES[focus_index] if focus!="" else "Not yet chosen","title")
	if focus!="":_label(portrait,String(PeopleDirection.AMBITIONS[focus].get("effect","")),"small")
	var spacer:=Control.new();spacer.size_flags_vertical=SIZE_EXPAND_FILL;portrait.add_child(spacer)
	P.kicker(portrait,"Who decides day to day")
	for area in ["scouting","settlement","research"]:
		var delegated:bool=state.get("auto_"+area)
		var control:=HBoxContainer.new();control.add_theme_constant_override("separation",8);portrait.add_child(control)
		var area_name:String={"scouting":"Where scouts go","settlement":"Where new homes are built","research":"What people study"}[area]
		var label:=_label(control,"%s: %s" % [area_name,"our leaders decide" if delegated else "you decide"],"body");label.size_flags_horizontal=SIZE_EXPAND_FILL
		var toggle:=_button(control,"I will decide" if delegated else "Let leaders decide",func():state.set_delegated(area,not delegated);_traditions_page())
		toggle.custom_minimum_size.x=150
	var values:=_box(spread);values.add_theme_constant_override("separation",6)
	_label(values,"What we inherit","title")
	_label(values,"Each bar shows how the people lean today. The dark mark shows what earlier generations handed down. Hover a part of a bar for its share.","small")
	for domain:Dictionary in state.cultural_tendencies():
		var head:=HBoxContainer.new();values.add_child(head)
		var label:=_label(head,_plain(String(domain.domain)),"body",T.INK);label.size_flags_horizontal=SIZE_EXPAND_FILL
		var strongest:="";var best:=0.0
		for pole in domain.current:
			if float(domain.current[pole])>best:strongest=String(pole);best=float(domain.current[pole])
		var dominant:=_label(head,_plain(strongest) if best>0 else "Not yet formed","body",T.GOLD_TEXT)
		dominant.autowrap_mode=TextServer.AUTOWRAP_OFF
		var track:=HBoxContainer.new();track.custom_minimum_size.y=15;track.add_theme_constant_override("separation",3);values.add_child(track)
		var i:=0
		for pole in domain.current:
			var segment:=Control.new();segment.size_flags_horizontal=SIZE_EXPAND_FILL;segment.custom_minimum_size.y=15;segment.mouse_filter=Control.MOUSE_FILTER_STOP
			var current:=float(domain.current[pole]);var inherited:=float(domain.inheritance[pole]);var color:Color=VALUE_COLORS[i];i+=1
			segment.tooltip_text="%s\nToday %.0f%% · handed down %.0f%%"%[_plain(String(pole)),current*100,inherited*100]
			segment.draw.connect(func():
				segment.draw_rect(Rect2(Vector2.ZERO,segment.size),T.PAPER_SUNK)
				segment.draw_rect(Rect2(Vector2.ZERO,Vector2(segment.size.x*current,15)),color)
				if inherited>0:segment.draw_line(Vector2(segment.size.x*inherited,2),Vector2(segment.size.x*inherited,13),T.INK,2))
			segment.resized.connect(segment.queue_redraw);track.add_child(segment)
	var history:=_box(traditions)
	_label(history,"The choices we carry","title")
	var timeline_scroll:=ScrollContainer.new();timeline_scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;history.add_child(timeline_scroll)
	var timeline:=HBoxContainer.new();timeline.add_theme_constant_override("separation",12);timeline_scroll.add_child(timeline)
	var commitments:Array=[]
	for event:Dictionary in state.cultural_memory.events:
		if String(event.id).begins_with("century:") or String(event.id).begins_with("legacy:"):commitments.append(event)
	for event:Dictionary in commitments:
		var tile:=VBoxContainer.new();tile.custom_minimum_size.x=160;timeline.add_child(tile)
		var index:=maxi(0,PeopleDirection.AMBITIONS.keys().find(String(event.choice)))
		var art:=_art(tile,index,70);art.tooltip_text=CARD_TITLES[index]
		_label(tile,String(PeopleDirection.AMBITIONS[event.choice].name),"small",T.INK)
		_label(tile,EraWords.when(int(event.day)),"small")
	if commitments.is_empty():
		timeline_scroll.hide()
		_label(history,"Your first choice begins the story.","body")
	# The one-shot visions have become generational aims (legacy_aims.gd):
	# the court proposes them and the god takes one up in the Court.
	var aims:=preload("res://scripts/legacy_aims.gd").board_model()
	var aim_row:=_box(traditions)
	var live:Dictionary=aims.get("active",{})
	if not live.is_empty():
		_label(aim_row,"What we strive for: %s" % String(live.title),"value",T.INK)
		_label(aim_row,"%s · %s left · %s" % [String(live.words).substr(0,1).to_upper()+String(live.words).substr(1),String(live.left),String(live.by)],"body")
	elif String(aims.get("waiting",""))!="":
		_label(aim_row,"The people want an aim. Summon %s in the court to hear it." % String(aims.waiting),"body",T.INK)
	else:
		_label(aim_row,"No aim is sworn. The court will speak of one when the time comes.","body")
	for legacy:Dictionary in aims.get("legacies",[]):
		_label(aim_row,"Remembered: %s (%s)" % [String(legacy.name),EraWords.when(int(legacy.day))],"small")

func _capture_opening()->void:
	if "--capture-opening" not in OS.get_cmdline_user_args() or get_tree().root.has_meta("opening_captured"):return
	get_tree().root.set_meta("opening_captured",true)
	for frame in 8:await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var result:=get_viewport().get_texture().get_image().save_png("res://artifacts/player-opening.png")
	print("OPENING_CAPTURE: ",result,"; day=",WorldSimulation.state.elapsed_days,"; opening=",opening)
