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

const CARD_TITLES:=["Know the world","Build to last","Bring us together","Seek knowledge","Build strength","Create abundance","Care for people","Trade & connect","Found new horizons","Rule & extract","Chosen people","Entrench a dynasty","Rule through fear","One official truth"]
const CARD_TAGS:=["LOGISTICS · ECOLOGY","CRAFT · BUILDING","CULTURE · INSTITUTIONS","KNOWLEDGE · HEALTH","SECURITY · LOGISTICS","NUTRITION · ECOLOGY","HEALTH · DEMOGRAPHY","PRODUCTION · LOGISTICS","LOGISTICS · DEMOGRAPHY","SECURITY · INSTITUTIONS","CULTURE · SECURITY","INSTITUTIONS · BUILDING","SECURITY · INSTITUTIONS","INSTITUTIONS · CULTURE"]
const CARD_COLORS:=["71bcb3","d8996a","d9b978","9ba7d6","cc7c68","b8c480","81c5ac","dbb57a","c7ac69","b27256","ac9a7b","bd985e","a46658","95859f"]
var title:Label
var layout:VBoxContainer

func _ready()->void:
	theme=Theme.new()
	theme.default_font=load("res://assets/fonts/battle/Barlow-Medium.ttf")
	theme.set_color("font_color","Label",Color("343d34"))
	opening=WorldSimulation.state.founding_focus==""
	if not WorldSimulation.direction.needs_century_choice():selected_focus=WorldSimulation.direction.ambition;reviewing=true
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background:=ColorRect.new();background.color=Color("eee9dd");background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(background)
	var margin:=MarginContainer.new();margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+edge,18)
	add_child(margin)
	layout=VBoxContainer.new();layout.add_theme_constant_override("separation",9);margin.add_child(layout)
	var top:=HBoxContainer.new();layout.add_child(top)
	title=_label(top,"YOUR PEOPLE’S STORY BEGINS",30);title.size_flags_horizontal=SIZE_EXPAND_FILL
	_button(top,"RETURN · F8",func():queue_free()).visible=not WorldSimulation.direction.needs_century_choice()
	summary=_label(layout,"",14)
	var tabs:=HBoxContainer.new();layout.add_child(tabs)
	for index in 3:
		var tab_index:=index
		_button(tabs,["Direction","Council","National character"][index],func():_show_page(tab_index))
	var body:=VBoxContainer.new();body.size_flags_vertical=SIZE_EXPAND_FILL;layout.add_child(body)
	var focus_page:=VBoxContainer.new();focus_page.size_flags_vertical=SIZE_EXPAND_FILL;body.add_child(focus_page);pages.append(focus_page)
	var cards_scroll:=ScrollContainer.new();cards_scroll.size_flags_vertical=SIZE_EXPAND_FILL;focus_page.add_child(cards_scroll)
	grid=GridContainer.new();grid.columns=4;grid.size_flags_vertical=SIZE_EXPAND_FILL;grid.size_flags_horizontal=SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation",10);grid.add_theme_constant_override("v_separation",10);cards_scroll.add_child(grid)
	var index:=0
	for id:String in PeopleDirection.AMBITIONS:
		var card:=preload("res://scripts/ambition_art_card.gd").new()
		card.custom_minimum_size.y=175;card.art_index=index%8;card.caption=CARD_TITLES[index];card.subtitle=CARD_TAGS[index];card.accent=Color(CARD_COLORS[index]);card.size_flags_horizontal=SIZE_EXPAND_FILL;card.size_flags_vertical=SIZE_EXPAND_FILL
		card.set_meta("ambition",id);card.tooltip_text=String(PeopleDirection.AMBITIONS[id].vision)
		card.pressed.connect(func():selected_focus=id;reviewing=true;_refresh())
		grid.add_child(card);ambition_buttons.append(card);focus_cards.append(card);index+=1
	choice_help=_label(focus_page,"",14)
	var detail:=_label(focus_page,"",14);detail.name="SelectionDetail";detail.custom_minimum_size.y=24
	var confirm:=_button(focus_page,"CHOOSE A DIRECTION ABOVE",func():
		var result:Dictionary=WorldSimulation.direction.choose(selected_focus)
		status.text=String(result.get("error","Focus chosen. Resume time when ready."))
		if not result.has("error"):queue_free())
	confirm.name="ConfirmFocus";confirm.custom_minimum_size.y=43
	var commit_style:=StyleBoxFlat.new();commit_style.bg_color=Color("c7a55f");commit_style.set_corner_radius_all(3);confirm.add_theme_stylebox_override("normal",commit_style);confirm.add_theme_color_override("font_color",Color("112126"));confirm.add_theme_font_size_override("font_size",16)
	council=VBoxContainer.new();body.add_child(council);pages.append(council)
	var traditions_scroll:=ScrollContainer.new();traditions_scroll.size_flags_vertical=SIZE_EXPAND_FILL;body.add_child(traditions_scroll);pages.append(traditions_scroll)
	traditions=VBoxContainer.new();traditions.size_flags_horizontal=SIZE_EXPAND_FILL;traditions_scroll.add_child(traditions)
	status=_label(layout,"",13);status.visible=false
	resized.connect(_refresh);_show_page(0 if WorldSimulation.direction.needs_century_choice() else 2)
	print("DIRECTION_SCREEN_READY: day=",WorldSimulation.state.elapsed_days,"; opening=",opening,"; settlement=",WorldSimulation.state.settlement_name,"; seed=",WorldSimulation.state.world_seed)
	_capture_opening.call_deferred()

func _label(parent:Node,text:String,font_size:int)->Label:
	var label:=Label.new(); label.text=text
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",font_size)
	if font_size>=24:label.add_theme_font_override("font",load("res://assets/fonts/cinzel/Cinzel.ttf"))
	parent.add_child(label)
	return label

func _button(parent:Node,text:String,action:Callable)->Button:
	var button:=Button.new(); button.text=text
	button.custom_minimum_size.y=34
	for kind in ["normal","hover","pressed","disabled","focus"]:
		var style:=StyleBoxFlat.new();style.bg_color=Color("e1dbc9") if kind=="normal" else Color("cec4aa")
		style.content_margin_left=14;style.content_margin_right=14;style.set_corner_radius_all(3)
		button.add_theme_stylebox_override(kind,style)
	button.add_theme_color_override("font_color",Color("343d34"))
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
	var century:=WorldSimulation.direction.century_at(int(WorldSimulation.state.elapsed_days))
	var pending:=WorldSimulation.direction.needs_century_choice()
	title.text="A people takes shape" if opening else "The character of a nation"
	title.add_theme_font_size_override("font_size",24 if size.x<1000 else 32)
	summary.text="Choose a founding purpose" if opening else "Years %d–%d  /  Century %d"%[century*100+1,(century+1)*100,century+1]
	grid.columns=2 if size.x<1000 else 4
	for card in ambition_buttons:
		card.disabled=not pending;card.select(String(card.get_meta("ambition"))==selected_focus)
	choice_help.visible=false
	var detail:=pages[0].get_node("SelectionDetail") as Label
	if selected_focus=="":detail.text="Every choice leaves a mark."
	else:
		var imprints:Array[String]=[]
		for domain in PeopleDirection.Culture.PROFILES[selected_focus]:
			for pole in PeopleDirection.Culture.PROFILES[selected_focus][domain]:imprints.append(String(pole).replace("_"," ").capitalize())
		detail.text="  ·  ".join(imprints)
		detail.tooltip_text=String(PeopleDirection.AMBITIONS[selected_focus].vision)
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
	var recommendations:=WorldSimulation.direction.advisor_recommendations()
	if recommendations.is_empty():
		_label(council,"No appointed advisor is available yet. You can still choose any focus.",16)
	for advice in recommendations:
		_label(council,"%s · %s — %s" % [advice.name,advice.title,PeopleDirection.AMBITIONS[advice.focus].name],16)
		_label(council,advice.reason,14)

const VALUE_COLORS:=[Color("8b9b76"),Color("ba945b"),Color("688b91"),Color("ac7564")]

func _art(parent:Node,index:int,height:float)->TextureRect:
	var rect:=TextureRect.new();rect.custom_minimum_size.y=height;rect.size_flags_horizontal=SIZE_EXPAND_FILL
	rect.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;rect.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var source:Texture2D=load("res://assets/ui/ambition_atlas_v1.png")
	var atlas:=AtlasTexture.new();atlas.atlas=source;atlas.region=Rect2(Vector2(index%4,index/4)*source.get_size()/Vector2(4,2),source.get_size()/Vector2(4,2));rect.texture=atlas
	parent.add_child(rect);return rect

func _box(parent:Node)->VBoxContainer:
	var panel:=PanelContainer.new();panel.size_flags_horizontal=SIZE_EXPAND_FILL
	var style:=StyleBoxFlat.new();style.bg_color=Color("f7f3e9");style.border_color=Color("d6cfbb");style.set_border_width_all(1)
	style.content_margin_left=16;style.content_margin_right=16;style.content_margin_top=14;style.content_margin_bottom=14
	panel.add_theme_stylebox_override("panel",style);parent.add_child(panel)
	var content:=VBoxContainer.new();content.add_theme_constant_override("separation",10);panel.add_child(content);return content

func _traditions_page()->void:
	_clear(traditions)
	traditions.add_theme_constant_override("separation",14)
	var state=WorldSimulation.direction
	var day:=int(WorldSimulation.state.elapsed_days)
	var spread:=BoxContainer.new();spread.vertical=size.x<900;spread.add_theme_constant_override("separation",18);traditions.add_child(spread)
	var portrait:=_box(spread);portrait.get_parent().size_flags_stretch_ratio=.85
	var focus:=String(state.ambition)
	var focus_index:=maxi(0,PeopleDirection.AMBITIONS.keys().find(focus))
	_art(portrait,focus_index%8,265)
	_label(portrait,"OUR PRESENT COURSE",12).add_theme_color_override("font_color",Color("8c764d"))
	_label(portrait,CARD_TITLES[focus_index] if focus!="" else "An unwritten story",26)
	_label(portrait,"Shaped by every generation",14)
	var spacer:=Control.new();spacer.size_flags_vertical=SIZE_EXPAND_FILL;portrait.add_child(spacer)
	for area in ["scouting","settlement","research"]:
		var delegated:bool=state.get("auto_"+area)
		var control:=HBoxContainer.new();portrait.add_child(control)
		var label:=_label(control,{"scouting":"Exploration","settlement":"Settlements","research":"Research"}[area],15);label.size_flags_horizontal=SIZE_EXPAND_FILL
		var toggle:=_button(control,"Leader" if delegated else "Manual",func():state.set_delegated(area,not delegated);_traditions_page())
		toggle.custom_minimum_size.x=105
		toggle.tooltip_text="Click to take control" if delegated else "Click to restore automatic orders shaped by your culture"
	var values:=_box(spread);values.add_theme_constant_override("separation",6)
	_label(values,"Cultural inheritance",25)
	var key:=_label(values,"Color: today   /   Markers: inherited weight",12);key.tooltip_text="Each domain has four independent poles. Hover a segment for its current and inherited share. Recent choices matter more today; earlier choices remain in the inheritance."
	for domain:Dictionary in state.cultural_tendencies():
		var head:=HBoxContainer.new();values.add_child(head)
		var label:=_label(head,String(domain.domain).capitalize(),14);label.size_flags_horizontal=SIZE_EXPAND_FILL
		var strongest:="";var best:=0.0
		for pole in domain.current:
			if float(domain.current[pole])>best:strongest=String(pole);best=float(domain.current[pole])
		var dominant:=_label(head,strongest.replace("_"," ").capitalize() if best>0 else "Unformed",14)
		dominant.autowrap_mode=TextServer.AUTOWRAP_OFF;dominant.add_theme_color_override("font_color",Color("8c764d"))
		var track:=HBoxContainer.new();track.custom_minimum_size.y=15;track.add_theme_constant_override("separation",3);values.add_child(track)
		var i:=0
		for pole in domain.current:
			var segment:=Control.new();segment.size_flags_horizontal=SIZE_EXPAND_FILL;segment.custom_minimum_size.y=15;segment.mouse_filter=Control.MOUSE_FILTER_STOP
			var current:=float(domain.current[pole]);var inherited:=float(domain.inheritance[pole]);var color:Color=VALUE_COLORS[i];i+=1
			segment.tooltip_text="%s\nToday %.0f%% · Inherited %.0f%%"%[String(pole).replace("_"," ").capitalize(),current*100,inherited*100]
			segment.draw.connect(func():
				segment.draw_rect(Rect2(Vector2.ZERO,segment.size),Color("e5dfd0"))
				segment.draw_rect(Rect2(Vector2.ZERO,Vector2(segment.size.x*current,15)),color)
				if inherited>0:segment.draw_line(Vector2(segment.size.x*inherited,2),Vector2(segment.size.x*inherited,13),Color("404b3b"),2))
			segment.resized.connect(segment.queue_redraw);track.add_child(segment)
	var history:=_box(traditions)
	var history_title:=HBoxContainer.new();history.add_child(history_title)
	_label(history_title,"The choices we carry",22).size_flags_horizontal=SIZE_EXPAND_FILL
	_label(history_title,"Permanent inheritance",12).autowrap_mode=TextServer.AUTOWRAP_OFF
	var timeline_scroll:=ScrollContainer.new();timeline_scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;history.add_child(timeline_scroll)
	var timeline:=HBoxContainer.new();timeline.add_theme_constant_override("separation",12);timeline_scroll.add_child(timeline)
	var commitments:Array=[]
	for event:Dictionary in state.cultural_memory.events:
		if String(event.id).begins_with("century:") or String(event.id).begins_with("legacy:"):commitments.append(event)
	for event:Dictionary in commitments:
		var tile:=VBoxContainer.new();tile.custom_minimum_size.x=145;timeline.add_child(tile)
		var index:=maxi(0,PeopleDirection.AMBITIONS.keys().find(String(event.choice)))
		var art:=_art(tile,index%8,70);art.tooltip_text=CARD_TITLES[index]
		_label(tile,"Y%d · %s"%[int(event.day)/365+1,String(PeopleDirection.AMBITIONS[event.choice].name)],12)
	if commitments.is_empty():_label(timeline,"Your first choice begins the story.",14)
	if state.ambition!="" and state.resolved<state.VISIONS.size() and day>=state.next_vision_day:
		var vision:Dictionary=state.VISIONS[state.resolved]
		var row:=_box(traditions);_label(row,vision.title,20)
		var options:=HBoxContainer.new();row.add_child(options)
		for index in 2:
			var choice_index:=index
			var option:=_button(options,vision.options[index].label,func():
				var result:Dictionary=state.decide(choice_index)
				status.text=String(result.get("error",""));status.visible=result.has("error");_traditions_page())
			option.tooltip_text=vision.question+"\n"+vision.options[index].meaning

func _capture_opening()->void:
	if "--capture-opening" not in OS.get_cmdline_user_args() or get_tree().root.has_meta("opening_captured"):return
	get_tree().root.set_meta("opening_captured",true)
	for frame in 8:await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var result:=get_viewport().get_texture().get_image().save_png("res://artifacts/player-opening.png")
	print("OPENING_CAPTURE: ",result,"; day=",WorldSimulation.state.elapsed_days,"; opening=",opening)
