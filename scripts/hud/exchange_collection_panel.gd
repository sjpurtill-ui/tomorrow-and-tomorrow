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
const PAGE_SIZE:=40
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
	panel.add_theme_stylebox_override("panel",P.sheet_style(20))
	outer=ScrollContainer.new();outer.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;panel.add_child(outer)
	var body:=VBoxContainer.new();body.size_flags_horizontal=SIZE_EXPAND_FILL;body.add_theme_constant_override("separation",10);outer.add_child(body)
	var header:=HBoxContainer.new();header.add_theme_constant_override("separation",12);body.add_child(header)
	var titles:=VBoxContainer.new();titles.size_flags_horizontal=SIZE_EXPAND_FILL;header.add_child(titles)
	P.kicker(titles,"Objects, knowledge and customs")
	label(titles,"Brought home","title",T.INK)
	var exit:=P.button(header,"Close",close);exit.name="Close";exit.size_flags_horizontal=SIZE_SHRINK_END;exit.custom_minimum_size=Vector2(96,38)
	P.rule(body)
	summary=label(body,"","body",T.BODY)
	offer_box=VBoxContainer.new();offer_box.name="OfferCard";offer_box.visible=false;body.add_child(offer_box)
	filter=OptionButton.new();filter.add_item("Everything brought home");filter.add_item("Objects and samples");filter.add_item("Knowledge");filter.add_item("Customs");filter.custom_minimum_size.y=36;filter.item_selected.connect(func(_value:int):page=0;refresh(true));body.add_child(filter)
	search=LineEdit.new();search.placeholder_text="Find a piece or a place";search.custom_minimum_size.y=36;search.text_changed.connect(func(_text:String):page=0;refresh(true));body.add_child(search)
	var navigation:=HBoxContainer.new();navigation.add_theme_constant_override("separation",8);body.add_child(navigation)
	previous_page=P.button(navigation,"Previous page",func():page=maxi(0,page-1);refresh(true));previous_page.size_flags_horizontal=SIZE_SHRINK_BEGIN;previous_page.custom_minimum_size.x=130
	page_label=label(navigation,"","small",T.INK_MUTED);page_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	next_page=P.button(navigation,"Next page",func():page+=1;refresh(true));next_page.size_flags_horizontal=SIZE_SHRINK_END;next_page.custom_minimum_size.x=130
	cards=VBoxContainer.new();cards.size_flags_horizontal=SIZE_EXPAND_FILL;cards.add_theme_constant_override("separation",8);body.add_child(cards)
	label(body,"Our thinkers study finds on their own, with a small share of their time. Keeping written notes makes the study faster. Once a find is understood it points toward a new idea, which still has to be worked out at home.","small",T.INK_MUTED)
	P.rule(body)
	P.kicker(body,"At home")
	choice(body,"Newcomers who ask to live with us",["balanced","welcome","consolidate"],["Take them in as room allows","Welcome them faster","Take no one for now"],String(E.data().migration_policy),func(value:String):E.policy(value,String(E.data().sharing_policy));refresh(true))
	choice(body,"What we teach other peoples",["open","selective","guarded"],["Share our ways openly","Share customs and simple crafts","Keep our skills to ourselves"],String(E.data().sharing_policy),func(value:String):E.policy(String(E.data().migration_policy),value);refresh(true))
	resized.connect(layout);layout();refresh(true)

## A plainly labelled choice: one caption and a row of worded buttons, the
## current one marked. (Real settings, so they stay; no hidden dropdown.)
func choice(parent:Node,caption:String,ids:Array,titles:Array,current:String,action:Callable)->void:
	var row:=VBoxContainer.new();row.add_theme_constant_override("separation",4);parent.add_child(row);label(row,caption,"body",T.INK)
	var buttons:=HFlowContainer.new();buttons.add_theme_constant_override("h_separation",6);buttons.add_theme_constant_override("v_separation",6);row.add_child(buttons)
	var group:=ButtonGroup.new()
	for index in ids.size():
		var id:=String(ids[index])
		var option:=P.button(buttons,String(titles[index]),Callable());option.size_flags_horizontal=SIZE_SHRINK_BEGIN;option.custom_minimum_size=Vector2(0,36)
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
	var sig:=str([state.collections.size(),state.history.size(),int(pressure.unsettled),int(GameState.elapsed_days),filter.selected,search.text,page])
	if not force and sig==signature:return
	signature=sig
	var collection:=A.summary()
	var lines:PackedStringArray=[]
	lines.append("We hold %s brought home from other places." % ("one find" if state.collections.size()==1 else "%d finds" % state.collections.size()))
	var settling:=ceili(float(pressure.unsettled))
	if settling>0 or E.reception_capacity()>0:lines.append("%d newcomers are still settling in; we have room to take in %d more." % [settling,E.reception_capacity()])
	if int(collection.count)>0 and (float(collection.science)>0.0 or float(collection.culture)>0.0):
		lines.append("Studying our old objects speeds learning by %s and the growth of customs by %s." % [_percent(float(collection.science)),_percent(float(collection.culture))])
	if float(E.data().get("museum_revenue",0))>0.0:lines.append("Visitors who come to see the pieces on show are paying their way.")
	if notice!="":lines.append(notice)
	summary.text=" ".join(lines)
	for child in cards.get_children():cards.remove_child(child);child.queue_free()
	var values:Array=state.collections.values();values.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return String(a.id)<String(b.id) if int(a.returned_day)==int(b.returned_day) else int(a.returned_day)>int(b.returned_day))
	var matching:Array=[]
	for item:Dictionary in values:
		if filter.selected==1 and item.kind not in ["artifact","specimen"]:continue
		if filter.selected==2 and item.kind!="knowledge":continue
		if filter.selected==3 and item.kind!="culture":continue
		if not search.text.is_empty() and not (String(item.name)+" "+String(item.source_name)).to_lower().contains(search.text.to_lower()):continue
		matching.append(item)
	var pages:=maxi(1,ceili(float(matching.size())/PAGE_SIZE))
	page=clampi(page,0,pages-1)
	previous_page.disabled=page==0;next_page.disabled=page>=pages-1
	page_label.text="Page %d of %d · %d finds" % [page+1,pages,matching.size()]
	var shown:=0
	for item:Dictionary in matching.slice(page*PAGE_SIZE,(page+1)*PAGE_SIZE):
		var card:=PanelContainer.new();card.add_theme_stylebox_override("panel",P.card_style(T.TEAL if float(item.study)>=1 else Color(0,0,0,0)));cards.add_child(card)
		var row:=HBoxContainer.new();row.add_theme_constant_override("separation",12);card.add_child(row)
		var presented:=ArtifactArt.presentation(item)
		var definition:=DiscoverySystem.discovery_definition(String(item.discovery_id))
		var artifact_texture:=ArtifactArt.texture(item)
		var icon:=TextureRect.new()
		if item.kind=="artifact":
			icon.texture=artifact_texture if artifact_texture!=null else V.icon("production")
			icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			var artifact_size:=72.0 if size.x<480 else 160.0
			icon.custom_minimum_size=Vector2(artifact_size,artifact_size) if artifact_texture!=null else Vector2(36,36)
		elif not definition.is_empty() and ResearchVisuals.thumbnail_for(definition)!=null:
			# A landscape thumbnail cropped around the painting's focus point:
			# wide banner paintings keep two thirds of their width.
			ResearchVisuals.paint_discovery(row,definition,84).custom_minimum_size.x=148
		else:
			icon.texture=V.icon("population" if item.kind=="culture" else "production" if item.kind=="specimen" else "logistics")
			icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.custom_minimum_size=Vector2(36,36)
		if icon.texture!=null:icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;row.add_child(icon)
		else:icon.free()
		var content:=VBoxContainer.new();content.size_flags_horizontal=SIZE_EXPAND_FILL;row.add_child(content)
		var origin:=String(presented.get("artifact_origin",""))
		P.kicker(content,"Ancient find" if origin=="prehistoric" else "Made by another people" if origin=="civilization" else String(KIND_WORDS.get(String(item.kind),String(item.kind))))
		label(content,String(presented.get("name",item.name)),"value",T.INK)
		label(content,"From %s. Found %s, brought home %s." % [item.source_name,EraWords.when(int(item.observed_day)),EraWords.when(int(item.returned_day))],"small",T.INK_MUTED)
		if not String(presented.get("insight","")).is_empty():label(content,String(presented.insight),"small",T.BODY)
		var bar:=ProgressBar.new();bar.show_percentage=false;bar.value=float(item.study)*100;bar.custom_minimum_size.y=6;content.add_child(bar)
		var known:=String(item.discovery_id) in GameState.known_discoveries
		label(content,"Understood and kept in our collection." if known else (("Understood. Ready to compare notes with its makers." if item.get("partnership_protocol",false) else "Understood. It points toward "+String(definition.get("name","a new idea")).to_lower()+".") if float(item.study)>=1 else "Still being studied, about %d%% understood." % roundi(float(item.study)*100)),"small",T.TEAL_TEXT)
		if item.get("partnership_protocol",false) and float(item.study)>=1:
			label(content,"We have learned what we can alone. Its makers could teach us the rest if we work with them on this idea.","small",T.GOLD_TEXT)
		if float(item.study)>=1 and not known and not item.get("partnership_protocol",false):
			var button:=P.button(content,"Turn our thinkers to "+String(definition.get("name","this idea")).to_lower(),Callable());button.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
			button.disabled=not DiscoverySystem._discovery_is_eligible(definition,int(GameState.elapsed_days)) if not definition.is_empty() else true
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
		shown+=1
		if shown>=PAGE_SIZE:break
	if shown==0:label(cards,"Explorers bring back samples from ground they visit. Peaceful meetings can bring objects, stories and customs. Finds appear here once their carriers return.","body",T.BODY)
	if not state.history.is_empty():label(cards,String(state.history[0].text),"small",T.INK_MUTED)
	_build_offer()

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
	var offer:=P.button(actions,"Offer it to another people",func():offer_id=String(item.id);offer_to="";offer_mode="";offer_want="";_build_offer();outer.scroll_vertical=0)
	offer.size_flags_horizontal=SIZE_SHRINK_BEGIN

func _recipient_name(id:String)->String:
	var owner:=E.owner_state(id)
	return String(owner.settlement_name) if owner!=null else "them"

func _cancel_offer()->void:
	offer_id="";offer_to="";offer_mode="";offer_want="";_build_offer()

## The single exchange card. Step by step: the piece (chosen on its own card),
## who receives it, how (give, sell or swap), then one confirmation line.
func _build_offer()->void:
	if not is_instance_valid(offer_box):return
	for child in offer_box.get_children():offer_box.remove_child(child);child.queue_free()
	var item:Dictionary=E.data().collections.get(offer_id,{})
	if offer_id=="" or item.get("kind","")!="artifact":offer_id="";offer_box.visible=false;return
	offer_box.visible=true
	var box:=P.card(offer_box,T.GOLD)
	P.kicker(box,"Offer a piece")
	var piece_name:=A.plain_name(item)
	label(box,"The %s" % piece_name,"value",T.INK)
	var contacts:Array[String]=[]
	for id:String in E.data().connections:
		if E.owner_state(id)==null or id=="player":continue
		contacts.append(id)
	if contacts.is_empty():
		label(box,"We have met no people at peace with us who could receive it yet.","body",T.BODY)
		_cancel_button(box)
		return
	label(box,"Who receives it?","small",T.INK_MUTED)
	var recipient:=OptionButton.new();recipient.name="Recipient";recipient.custom_minimum_size.y=36;recipient.fit_to_longest_item=false;recipient.clip_text=true
	recipient.add_item("Choose a people");recipient.set_item_metadata(0,"")
	for id:String in contacts:
		recipient.add_item(_recipient_name(id));recipient.set_item_metadata(recipient.item_count-1,id)
		if id==offer_to:recipient.select(recipient.item_count-1)
	recipient.item_selected.connect(func(index:int):offer_to=String(recipient.get_item_metadata(index));offer_mode="";offer_want="";_build_offer.call_deferred())
	box.add_child(recipient)
	if offer_to=="":
		_cancel_button(box)
		return
	var who:=_recipient_name(offer_to)
	label(box,"How?","small",T.INK_MUTED)
	var verbs:=HBoxContainer.new();verbs.add_theme_constant_override("separation",6);box.add_child(verbs)
	for mode:String in ["gift","sell","trade"]:
		if mode=="sell" and not _currency():continue
		var verb:=P.button(verbs,String(MODE_VERBS[mode]),Callable(),mode==offer_mode)
		verb.name="Verb_"+mode
		verb.pressed.connect(func():offer_mode=mode;offer_want="";_build_offer.call_deferred())
	if offer_mode=="trade":
		label(box,"Which of their pieces do you want in return?","small",T.INK_MUTED)
		var want:=OptionButton.new();want.name="Wanted";want.custom_minimum_size.y=36;want.fit_to_longest_item=false;want.clip_text=true
		want.add_item("Choose one of their pieces");want.set_item_metadata(0,"")
		var target:=E.owner_state(offer_to)
		if target!=null:
			for other:Dictionary in target.society_exchange.collections.values():
				if other.kind!="artifact":continue
				want.add_item(_upper_first(A.plain_name(other)));want.set_item_metadata(want.item_count-1,other.id)
				if String(other.id)==offer_want:want.select(want.item_count-1)
				if want.item_count>=41:break
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

func _cancel_button(parent:Node)->void:
	var cancel:=P.button(parent,"Cancel",_cancel_offer)
	cancel.size_flags_horizontal=SIZE_SHRINK_BEGIN;cancel.custom_minimum_size.x=120

static func _upper_first(text:String)->String:
	return text.substr(0,1).to_upper()+text.substr(1) if text!="" else text
