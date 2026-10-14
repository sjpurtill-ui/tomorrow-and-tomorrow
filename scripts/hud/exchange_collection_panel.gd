extends Control
## Brought home: every find our travellers carried back, and one simple way to
## hand a piece to another people (pick a piece, pick who, pick how, confirm).
const ArtifactArt=preload("res://scripts/hud/artifact_visuals.gd")
const A=preload("res://scripts/artifact_collection.gd")
var pause=preload("res://scripts/hud/simulation_pause.gd").new()
var search:LineEdit
const E=preload("res://scripts/society_exchange.gd")
const T=preload("res://scripts/hud/hud_tokens.gd")
const P=preload("res://scripts/hud/paper_sheet.gd")
const EraWords=preload("res://scripts/hud/era_words.gd")
const V=preload("res://scripts/hud/city_report_visuals.gd")
const ResearchVisuals=preload("res://scripts/hud/research_visuals.gd")
var panel:PanelContainer
var cards:VBoxContainer
var summary:Label
var timer:=0.0
var signature:=""
const PAGE_SIZE:=6
var selected_id:=""
var browse_open:=false
var browser_box:VBoxContainer
var choices:VBoxContainer
var select_piece:Button
var home_box:VBoxContainer
var home_toggle:Button
var study_help:Label
var study_toggle:Button
var reader_back:Button
var study_open:=false
var home_summary:Label
var narrow_layout:=false
var home_open:=false
var offer_query:=""
var page:=0
var previous_page:Button
var next_page:Button
var page_label:Label
var filter:OptionButton
var outer:ScrollContainer
## The one exchange card: the piece, who receives it, how, then a confirmation.
var offer_box:VBoxContainer
var offer_id:=""
var offer_to:=""
var offer_mode:=""
var offer_want:=""
## The last thing the player did here, shown under the summary.
var notice:=""
const KIND_WORDS:={"artifact":"Object","specimen":"Sample","knowledge":"Knowledge","culture":"Custom"}
const MODE_VERBS:={"gift":"Give it","sell":"Sell it","trade":"Swap it"}

static func open()->void:
	var root:=CivilizationSystem
	var previous:Variant=root.get_meta("exchange_collection_panel") if root.has_meta("exchange_collection_panel") else null
	if is_instance_valid(previous):previous.queue_free()
	var layer:=CanvasLayer.new();layer.layer=96;root.add_child(layer)
	root.set_meta("exchange_collection_panel",layer);layer.add_child(new())

func label(parent:Node,text:String,role:String="body",color:Color=Color(0,0,0,0))->Label:
	var node:=P.label(parent,text,role,color);node.size_flags_horizontal=SIZE_EXPAND_FILL;return node
func close()->void:get_parent().queue_free()
func _exit_tree()->void:pause.release()
func _ready()->void:
	pause.acquire(get_tree().current_scene)
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	theme=T.control_theme()
	var dim:=ColorRect.new();dim.color=T.SCRIM;dim.set_anchors_and_offsets_preset(PRESET_FULL_RECT);add_child(dim)
	dim.gui_input.connect(func(event:InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:dim.accept_event();close())
	panel=PanelContainer.new();add_child(panel)
	panel.minimum_size_changed.connect(func():layout.call_deferred())
	panel.add_theme_stylebox_override("panel",P.sheet_style(20))
	var chrome:=VBoxContainer.new();chrome.add_theme_constant_override("separation",16);panel.add_child(chrome)
	outer=ScrollContainer.new();outer.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;outer.size_flags_vertical=SIZE_EXPAND_FILL;chrome.add_child(outer)
	var body:=VBoxContainer.new();body.size_flags_horizontal=SIZE_EXPAND_FILL;body.add_theme_constant_override("separation",16);outer.add_child(body)
	var header:=HBoxContainer.new();header.add_theme_constant_override("separation",12);chrome.add_child(header);chrome.move_child(header,0)
	var titles:=VBoxContainer.new();titles.size_flags_horizontal=SIZE_EXPAND_FILL;header.add_child(titles)
	P.kicker(titles,"Objects, knowledge and customs")
	label(titles,"Brought home","title",T.INK)
	var exit:=P.button(header,"Close",close);exit.name="Close";exit.size_flags_horizontal=SIZE_SHRINK_END;exit.custom_minimum_size=Vector2(96,40)
	P.rule(body)
	summary=label(body,"","body",T.BODY)
	offer_box=VBoxContainer.new();offer_box.name="OfferCard";offer_box.visible=false;body.add_child(offer_box)
	reader_back=P.button(body,"Back to selected piece",func():home_open=false;study_open=false;_sync_view();outer.scroll_vertical=0);reader_back.name="BackToPiece";reader_back.size_flags_horizontal=SIZE_SHRINK_BEGIN;reader_back.autowrap_mode=TextServer.AUTOWRAP_OFF
	select_piece=P.button(body,"Choose a piece",func():browse_open=not browse_open;_sync_view());select_piece.name="ChoosePiece";select_piece.size_flags_horizontal=SIZE_SHRINK_BEGIN;select_piece.autowrap_mode=TextServer.AUTOWRAP_OFF
	browser_box=VBoxContainer.new();browser_box.name="CollectionBrowser";browser_box.add_theme_constant_override("separation",8);body.add_child(browser_box)
	filter=OptionButton.new();filter.add_item("Everything brought home");filter.add_item("Objects and samples");filter.add_item("Knowledge");filter.add_item("Customs");T.apply_button_style(filter);filter.custom_minimum_size.y=44;filter.item_selected.connect(func(_value:int):page=0;refresh(true));browser_box.add_child(filter)
	search=LineEdit.new();search.placeholder_text="Find a piece or a place";search.add_theme_font_size_override("font_size",16);search.custom_minimum_size.y=44;search.text_changed.connect(func(_text:String):page=0;refresh(true));browser_box.add_child(search)
	var navigation:=HBoxContainer.new();navigation.add_theme_constant_override("separation",8);browser_box.add_child(navigation)
	previous_page=P.button(navigation,"Previous",func():page=maxi(0,page-1);refresh(true));previous_page.size_flags_horizontal=SIZE_SHRINK_BEGIN;previous_page.custom_minimum_size.x=90
	page_label=label(navigation,"","small",T.INK_MUTED);page_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	next_page=P.button(navigation,"Next",func():page+=1;refresh(true));next_page.size_flags_horizontal=SIZE_SHRINK_END;next_page.custom_minimum_size.x=90
	choices=VBoxContainer.new();choices.name="CollectionChoices";choices.add_theme_constant_override("separation",6);browser_box.add_child(choices)
	cards=VBoxContainer.new();cards.size_flags_horizontal=SIZE_EXPAND_FILL;cards.add_theme_constant_override("separation",8);body.add_child(cards)
	study_toggle=P.button(body,"How finds are studied",func():study_open=not study_open;_sync_view());study_toggle.name="StudyHelp";study_toggle.size_flags_horizontal=SIZE_SHRINK_BEGIN;study_toggle.autowrap_mode=TextServer.AUTOWRAP_OFF
	study_help=label(body,"Our thinkers study finds on their own, with a small share of their time. Keeping written notes makes the study faster. Once a find is understood it points toward a new idea, which still has to be worked out at home.","small",T.INK_MUTED)
	home_toggle=P.button(body,"Visitors & sharing",func():home_open=true;study_open=false;_sync_view();outer.scroll_vertical=0);home_toggle.name="HomePolicies";home_toggle.size_flags_horizontal=SIZE_SHRINK_BEGIN;home_toggle.autowrap_mode=TextServer.AUTOWRAP_OFF
	home_box=VBoxContainer.new();home_box.name="HomePoliciesBody";home_box.add_theme_constant_override("separation",12);body.add_child(home_box)
	var policies_title:=label(home_box,"Visitors & sharing","body",T.INK);policies_title.add_theme_font_override("font",T.font("ui_strong"));policies_title.add_theme_font_size_override("font_size",24)
	home_summary=label(home_box,"","body",T.BODY)
	choice(home_box,"Newcomers who ask to live with us",["balanced","welcome","consolidate"],["Take them in as room allows","Welcome them faster","Take no one for now"],String(E.data().migration_policy),func(value:String):E.policy(value,String(E.data().sharing_policy));refresh(true))
	choice(home_box,"What we teach other peoples",["open","selective","guarded"],["Share our ways openly","Share customs and simple crafts","Keep our skills to ourselves"],String(E.data().sharing_policy),func(value:String):E.policy(String(E.data().migration_policy),value);refresh(true))
	resized.connect(layout);layout();refresh(true)

## A plainly labelled choice: one caption and a row of worded buttons, the
## current one marked. (Real settings, so they stay; no hidden dropdown.)
func choice(parent:Node,caption:String,ids:Array,titles:Array,current:String,action:Callable)->void:
	var row:=VBoxContainer.new();row.add_theme_constant_override("separation",4);parent.add_child(row);label(row,caption,"body",T.INK)
	var buttons:=HFlowContainer.new();buttons.add_theme_constant_override("h_separation",6);buttons.add_theme_constant_override("v_separation",6);row.add_child(buttons)
	var group:=ButtonGroup.new()
	for index in ids.size():
		var id:=String(ids[index])
		var option:=P.button(buttons,String(titles[index]),Callable());option.size_flags_horizontal=SIZE_SHRINK_BEGIN;option.custom_minimum_size=Vector2(0,40)
		option.toggle_mode=true;option.button_group=group;option.button_pressed=id==current
		option.add_theme_stylebox_override("hover_pressed",T.button_pressed_style())
		option.pressed.connect(func():action.call(id))
func layout()->void:
	if not is_instance_valid(panel):return
	var style:StyleBox=panel.get_theme_stylebox("panel")
	if style is StyleBoxFlat:
		var margin:float=8.0 if size.x<420 else 20.0
		style.content_margin_left=margin;style.content_margin_right=margin
	panel.size=Vector2(minf(690,size.x-24),maxf(160,minf(800,size.y-24)));panel.position=(size-panel.size)*.5
	if narrow_layout!=(size.x<480):
		narrow_layout=size.x<480
		if is_instance_valid(cards):refresh.call_deferred(true)
func _unhandled_key_input(event:InputEvent)->void:
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:close();get_viewport().set_input_as_handled()
func _process(delta:float)->void:
	if not is_visible_in_tree():return
	timer+=delta
	if timer<1.0:return
	timer=0.0
	# A live refresh keeps the reader's scroll, focus and page in place.
	var view:=preload("res://scripts/hud/view_state.gd").capture(self)
	refresh(false)
	preload("res://scripts/hud/view_state.gd").restore(self,view)

func _percent(value:float)->String:
	return "%d%%" % roundi(value*100.0)

func refresh(force:bool)->void:
	var state:=E.data();var pressure:=E.pressure()
	var sig:=str([state.collections.size(),state.history.size(),int(pressure.unsettled),int(GameState.elapsed_days),filter.selected,search.text,page,selected_id])
	if not force and sig==signature:return
	signature=sig
	var collection:=A.summary()
	var lines:PackedStringArray=[]
	lines.append("%s brought home." % ("One find" if state.collections.size()==1 else "%d finds" % state.collections.size()))
	var settling:=ceili(float(pressure.unsettled))
	home_summary.text="%d newcomers are still settling in; we have room to take in %d more." % [settling,E.reception_capacity()]
	if int(collection.count)>0 and (float(collection.science)>0.0 or float(collection.culture)>0.0):
		lines.append("Study adds %s to learning and %s to the growth of customs." % [_percent(float(collection.science)),_percent(float(collection.culture))])
	if float(E.data().get("museum_revenue",0))>0.0:lines.append("Visitors who come to see the pieces on show are paying their way.")
	if notice!="":lines.append(notice)
	summary.text=" ".join(lines)
	for child in cards.get_children():cards.remove_child(child);child.queue_free()
	var values:Array=state.collections.values();values.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return String(a.id)<String(b.id) if int(a.returned_day)==int(b.returned_day) else int(a.returned_day)>int(b.returned_day))
	var selected:Dictionary=state.collections.get(selected_id,{})
	if selected.is_empty() and not values.is_empty():selected=values[0];selected_id=String(selected.id)
	if selected.is_empty():selected_id=""
	var matching:Array=[]
	for item:Dictionary in values:
		if filter.selected==1 and item.kind not in ["artifact","specimen"]:continue
		if filter.selected==2 and item.kind!="knowledge":continue
		if filter.selected==3 and item.kind!="culture":continue
		var shown_name:=String(ArtifactArt.presentation(item).get("name",item.name))
		if not search.text.strip_edges().is_empty() and not (shown_name+" "+String(item.name)+" "+String(item.source_name)).to_lower().contains(search.text.strip_edges().to_lower()):continue
		matching.append(item)
	var pages:=maxi(1,ceili(float(matching.size())/PAGE_SIZE))
	page=clampi(page,0,pages-1)
	previous_page.disabled=page==0;next_page.disabled=page>=pages-1
	previous_page.visible=pages>1;next_page.visible=pages>1
	page_label.text="Page %d of %d · %d finds" % [page+1,pages,matching.size()] if pages>1 else "%d finds" % matching.size()
	for child:Node in choices.get_children():choices.remove_child(child);child.queue_free()
	for item:Dictionary in matching.slice(page*PAGE_SIZE,(page+1)*PAGE_SIZE):
		var item_id:=String(item.id)
		var button:=P.button(choices,String(ArtifactArt.presentation(item).get("name",item.name)),func():selected_id=item_id;browse_open=false;refresh(true);outer.scroll_vertical=0)
		button.name="Find_"+item_id.validate_node_name();button.alignment=HORIZONTAL_ALIGNMENT_LEFT;button.autowrap_mode=TextServer.AUTOWRAP_OFF;button.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		button.tooltip_text="%s · from %s · %d%% understood" % [String(item.name),String(item.source_name),roundi(float(item.study)*100.0)]
		if item_id==selected_id:button.add_theme_stylebox_override("normal",button.get_theme_stylebox("pressed").duplicate())
	if matching.is_empty():label(choices,"No matching finds. Try another name or kind.","body",T.INK_MUTED)
	if not selected.is_empty():_show_item(selected)
	else:label(cards,"Explorers bring back samples from ground they visit. Peaceful meetings can bring objects, stories and customs. Finds appear here once their carriers return.","body",T.BODY)
	if not state.history.is_empty():label(cards,String(state.history[0].text),"small",T.INK_MUTED)
	_build_offer();_sync_view()

func _sync_view()->void:
	if not is_instance_valid(browser_box):return
	var offering:=not offer_id.is_empty()
	var explaining:=home_open
	var reading:=not browse_open and not offering and not explaining
	summary.visible=not explaining and not offering
	browser_box.visible=browse_open and not offering and not explaining
	cards.visible=reading
	reader_back.visible=explaining and not offering
	study_toggle.visible=reading
	study_help.visible=study_open and reading
	study_toggle.text="Hide study explanation" if study_open else "How finds are studied"
	reader_back.text="Back to collection" if selected_id.is_empty() else "Back to selected piece"
	select_piece.visible=not offering and not explaining and not E.data().collections.is_empty()
	select_piece.text="Back to selected piece" if browse_open else "Choose a piece · %d %s" % [E.data().collections.size(),"find" if E.data().collections.size()==1 else "finds"]
	home_toggle.visible=reading
	home_box.visible=home_open and not offering

func _show_item(item:Dictionary)->void:
	var card:=PanelContainer.new();card.add_theme_stylebox_override("panel",P.card_style(T.TEAL if float(item.study)>=1 else Color(0,0,0,0)));cards.add_child(card)
	var row:=BoxContainer.new();row.vertical=size.x<480;row.add_theme_constant_override("separation",12);card.add_child(row)
	var presented:=ArtifactArt.presentation(item)
	var definition:=DiscoverySystem.discovery_definition(String(item.discovery_id))
	var artifact_texture:=ArtifactArt.texture(item)
	var icon:=TextureRect.new()
	if item.kind=="artifact":
		icon.texture=artifact_texture if artifact_texture!=null else V.icon("production")
		icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var artifact_size:=100.0 if size.x<480 else 160.0
		icon.custom_minimum_size=Vector2(artifact_size,artifact_size) if artifact_texture!=null else Vector2(36,36)
	elif not definition.is_empty() and ResearchVisuals.thumbnail_for(definition)!=null:
		# A landscape thumbnail cropped around the painting's focus point:
		# wide banner paintings keep two thirds of their width.
		ResearchVisuals.paint_discovery(row,definition,84).custom_minimum_size.x=148
	else:
		icon.texture=V.icon("population" if item.kind=="culture" else "production" if item.kind=="specimen" else "logistics")
		icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size=Vector2(36,36)
	if icon.texture!=null:icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.size_flags_horizontal=SIZE_SHRINK_BEGIN;row.add_child(icon)
	else:icon.free()
	var content:=VBoxContainer.new();content.size_flags_horizontal=SIZE_EXPAND_FILL;row.add_child(content)
	var origin:=String(presented.get("artifact_origin",""))
	P.kicker(content,"Ancient find" if origin=="prehistoric" else "Made by another people" if origin=="civilization" else String(KIND_WORDS.get(String(item.kind),String(item.kind))))
	var title:=label(content,String(presented.get("name",item.name)),"body",T.INK);title.add_theme_font_override("font",T.font("ui_strong"));title.add_theme_font_size_override("font_size",24)
	label(content,"From %s. Found %s, brought home %s." % [item.source_name,EraWords.when(int(item.observed_day)),EraWords.when(int(item.returned_day))],"small",T.INK_MUTED)
	if not String(presented.get("insight","")).is_empty():label(content,String(presented.insight),"small",T.BODY)
	var bar:=ProgressBar.new();bar.show_percentage=false;bar.value=float(item.study)*100;bar.custom_minimum_size.y=6;bar.visible=float(item.study)<1.0;content.add_child(bar)
	var known:=String(item.discovery_id) in GameState.known_discoveries
	var study_status:=label(content,"Understood and kept in our collection." if known else (("Understood. Ready to compare notes with its makers." if item.get("partnership_protocol",false) else "Understood. It points toward "+String(definition.get("name","a new idea")).to_lower()+".") if float(item.study)>=1 else "Still being studied, about %d%% understood." % roundi(float(item.study)*100)),"small",T.TEAL_TEXT)
	study_status.tooltip_text="%d%% understood" % roundi(float(item.study)*100)
	if item.get("partnership_protocol",false) and float(item.study)>=1:
		label(content,"We have learned what we can alone. Its makers could teach us the rest if we work with them on this idea.","small",T.GOLD_TEXT)
	if float(item.study)>=1 and not known and not item.get("partnership_protocol",false):
		var button:=P.button(content,"Turn our thinkers to "+String(definition.get("name","this idea")).to_lower(),Callable());button.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		button.disabled=not DiscoverySystem._discovery_is_eligible(definition,int(GameState.elapsed_days)) if not definition.is_empty() else true
		T.apply_button_style(button,not button.disabled)
		var needs:Array[String]=[]
		if button.disabled:
			for requirement:Dictionary in definition.get("resource_requirements",[]):
				if not DiscoverySystem._resource_requirements_met([requirement]):needs.append(String(requirement.resource).to_lower())
			if needs.is_empty():needs.append("other ideas and the right conditions at home")
			label(content,"First we need "+", ".join(needs)+".","small",T.GOLD_TEXT)
		button.tooltip_text="Uses the thinkers we already have. Materials and earlier ideas are still needed."
		button.pressed.connect(func():
			var result:=DiscoverySystem.select_research_target(String(item.discovery_id))
			notice=String(result.error) if result.has("error") else "Our thinkers now work toward "+String(definition.name).to_lower()+"."
			refresh(true))
	if item.kind=="artifact":artifact_actions(content,item)

func _currency()->bool:
	return String(WorldSimulation.state.economy_stage)=="currency"

func artifact_actions(content:Node,item:Dictionary)->void:
	var tier:=String(A.TIERS[clampi(int(item.get("rarity",0)),0,A.TIERS.size()-1)])
	var years:=float(item.get("held_days",0))/365.0
	var held:String="kept by us for %d years" % int(years) if years>=2.0 else ("kept by us for about a year" if years>=1.0 else "new to us")
	label(content,"%s piece, %s%s." % [tier,held,(", worth about %d coins" % roundi(A.price(item))) if _currency() else ""],"small",T.GOLD_TEXT)
	var actions:=HFlowContainer.new();actions.add_theme_constant_override("h_separation",6);actions.add_theme_constant_override("v_separation",6);content.add_child(actions)
	var display:=P.button(actions,"Take it off show" if item.get("exhibited",false) else "Put it on show",func():A.exhibit(String(item.id));refresh(true))
	display.size_flags_horizontal=SIZE_SHRINK_BEGIN;display.disabled=not A.museum_ready()
	display.tooltip_text="Needs public libraries and compared chronicles before pieces can be shown to visitors." if display.disabled else "Visitors who come to see studied pieces pay their way once we use money."
	var offer:=P.button(actions,"Offer to another people",func():offer_id=String(item.id);offer_to="";offer_mode="";offer_want="";offer_query="";_build_offer();outer.scroll_vertical=0)
	offer.size_flags_horizontal=SIZE_SHRINK_BEGIN

func _recipient_name(id:String)->String:
	var owner:=E.owner_state(id)
	return String(owner.settlement_name) if owner!=null else "them"

func _cancel_offer()->void:
	offer_id="";offer_to="";offer_mode="";offer_want="";offer_query="";_build_offer()

## The single exchange card. Step by step: the piece (chosen on its own card),
## who receives it, how (give, sell or swap), then one confirmation line.
func _build_offer()->void:
	if not is_instance_valid(offer_box):return
	var focused:=get_viewport().gui_get_focus_owner()
	var focus_name:=String(focused.name) if focused!=null and offer_box.is_ancestor_of(focused) else ""
	_restore_offer_focus.call_deferred(focus_name)
	for child in offer_box.get_children():offer_box.remove_child(child);child.queue_free()
	var item:Dictionary=E.data().collections.get(offer_id,{})
	if offer_id=="" or item.get("kind","")!="artifact":offer_id="";offer_box.visible=false;_sync_view();return
	offer_box.visible=true;_sync_view()
	var box:=P.card(offer_box,T.GOLD)
	P.kicker(box,"Offer a piece")
	var piece_name:=A.plain_name(item)
	var heading:=label(box,"The %s" % piece_name,"body",T.INK);heading.add_theme_font_override("font",T.font("ui_strong"));heading.add_theme_font_size_override("font_size",24)
	var contacts:Array[String]=[]
	for id:String in E.data().connections:
		if E.owner_state(id)==null or id=="player":continue
		contacts.append(id)
	if contacts.is_empty():
		label(box,"We have met no people at peace with us who could receive it yet.","body",T.BODY)
		_cancel_button(box)
		return
	label(box,"Who receives it?","small",T.INK_MUTED)
	var recipient:=OptionButton.new();recipient.name="Recipient";T.apply_button_style(recipient);recipient.custom_minimum_size.y=44;recipient.fit_to_longest_item=false;recipient.clip_text=true;recipient.get_popup().max_size.y=320
	recipient.add_item("Choose a people");recipient.set_item_metadata(0,"")
	for id:String in contacts:
		recipient.add_item(_recipient_name(id));recipient.set_item_metadata(recipient.item_count-1,id)
		if id==offer_to:recipient.select(recipient.item_count-1)
	recipient.item_selected.connect(func(index:int):offer_to=String(recipient.get_item_metadata(index));offer_mode="";offer_want="";offer_query="";_build_offer.call_deferred())
	box.add_child(recipient)
	if offer_to=="":
		_cancel_button(box)
		return
	var who:=_recipient_name(offer_to)
	label(box,"How?","small",T.INK_MUTED)
	var verbs:=HFlowContainer.new();verbs.add_theme_constant_override("h_separation",6);verbs.add_theme_constant_override("v_separation",6);box.add_child(verbs)
	for mode:String in ["gift","sell","trade"]:
		if mode=="sell" and not _currency():continue
		var verb:=P.button(verbs,String(MODE_VERBS[mode]),Callable())
		verb.name="Verb_"+mode;verb.toggle_mode=true;verb.button_pressed=mode==offer_mode
		verb.pressed.connect(func():offer_mode=mode;offer_want="";offer_query="";_build_offer.call_deferred())
	if offer_mode=="trade":
		label(box,"Which of their pieces do you want in return?","small",T.INK_MUTED)
		var find:=LineEdit.new();find.name="FindTheirPiece";find.placeholder_text="Find one of their pieces";find.text=offer_query;find.custom_minimum_size.y=40;box.add_child(find)
		find.text_changed.connect(func(words:String):offer_query=words;offer_want="";_build_offer.call_deferred())
		var want:=OptionButton.new();want.name="Wanted";T.apply_button_style(want);want.custom_minimum_size.y=40;want.fit_to_longest_item=false;want.clip_text=true;want.get_popup().max_size.y=320
		want.add_item("Choose one of their pieces");want.set_item_metadata(0,"")
		var target:=E.owner_state(offer_to)
		if target!=null:
			for other:Dictionary in target.society_exchange.collections.values():
				if other.kind!="artifact":continue
				if not offer_query.strip_edges().is_empty() and not A.plain_name(other).to_lower().contains(offer_query.strip_edges().to_lower()):continue
				want.add_item(_upper_first(A.plain_name(other)));want.set_item_metadata(want.item_count-1,other.id)
				if String(other.id)==offer_want:want.select(want.item_count-1)
		want.item_selected.connect(func(index:int):offer_want=String(want.get_item_metadata(index));_build_offer.call_deferred())
		box.add_child(want)
	if offer_mode=="" or (offer_mode=="trade" and offer_want==""):
		_cancel_button(box)
		return
	# The one confirmation line.
	P.rule(box)
	var question:=""
	match offer_mode:
		"gift":question="Give the %s to %s?" % [piece_name,who]
		"sell":question="Sell the %s to %s for about %d coins?" % [piece_name,who,roundi(A.price(item))]
		"trade":
			var target:=E.owner_state(offer_to)
			var theirs:Dictionary=target.society_exchange.collections.get(offer_want,{}) if target!=null else {}
			question="Swap the %s for their %s?" % [piece_name,A.plain_name(theirs) if not theirs.is_empty() else "piece"]
	var checked:=A.check(offer_id,offer_to,offer_mode,offer_want)
	label(box,question,"body",T.INK)
	if checked.has("error"):label(box,String(checked.error),"small",T.RED_TEXT)
	var confirm_row:=HBoxContainer.new();confirm_row.add_theme_constant_override("separation",8);box.add_child(confirm_row)
	var confirm:=P.button(confirm_row,"Confirm",Callable(),true)
	confirm.pressed.connect(func():
		var result:=A.transfer(offer_id,offer_to,offer_mode,offer_want)
		if result.has("error"):notice=String(result.error)
		else:
			notice=question.trim_suffix("?").replace("Give","Gave").replace("Sell","Sold").replace("Swap","Swapped")+"."
			offer_id="";offer_to="";offer_mode="";offer_want=""
		refresh(true))
	confirm.name="ConfirmOffer";confirm.disabled=checked.has("error")
	P.button(confirm_row,"Cancel",_cancel_offer)

func _restore_offer_focus(node_name:String)->void:
	if node_name!="FindTheirPiece":return
	var find:=offer_box.find_child(node_name,true,false) as LineEdit
	if find!=null:find.grab_focus();find.caret_column=find.text.length()

func _cancel_button(parent:Node)->void:
	var cancel:=P.button(parent,"Cancel",_cancel_offer)
	cancel.size_flags_horizontal=SIZE_SHRINK_BEGIN;cancel.custom_minimum_size.x=120;cancel.autowrap_mode=TextServer.AUTOWRAP_OFF

static func _upper_first(text:String)->String:
	return text.substr(0,1).to_upper()+text.substr(1) if text!="" else text
