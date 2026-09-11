extends Control
const ArtifactArt=preload("res://scripts/hud/artifact_visuals.gd")
const A=preload("res://scripts/artifact_collection.gd")
var pause=preload("res://scripts/hud/simulation_pause.gd").new()
var page:=0
var search:LineEdit
const E=preload("res://scripts/society_exchange.gd")
const T=preload("res://scripts/hud/hud_tokens.gd")
const V=preload("res://scripts/hud/city_report_visuals.gd")
var panel:PanelContainer
var cards:VBoxContainer
var summary:Label
var timer:=0.0
var signature:=""
var filter:OptionButton

static func open()->void:
	var root:=CivilizationSystem
	var previous:Variant=root.get_meta("exchange_collection_panel",null)
	if is_instance_valid(previous):previous.queue_free()
	var layer:=CanvasLayer.new();layer.layer=96;root.add_child(layer)
	root.set_meta("exchange_collection_panel",layer);layer.add_child(new())

func label(parent:Node,text:String,size:int=14,color:Color=T.BODY)->Label:
	var node:=T.make_label(text,size,color);node.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;node.size_flags_horizontal=SIZE_EXPAND_FILL;parent.add_child(node);return node
func close()->void:get_parent().queue_free()
func _exit_tree()->void:pause.release()
func _ready()->void:
	pause.acquire(get_tree().current_scene)
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var dim:=ColorRect.new();dim.color=Color(.01,.02,.03,.72);dim.set_anchors_and_offsets_preset(PRESET_FULL_RECT);add_child(dim)
	dim.gui_input.connect(func(event:InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:dim.accept_event();close())
	panel=PanelContainer.new();add_child(panel)
	var style:=T.flat(T.DOCK_BG,T.BORDER_2,1,10);style.content_margin_left=20;style.content_margin_right=20;style.content_margin_top=16;style.content_margin_bottom=16;panel.add_theme_stylebox_override("panel",style)
	var outer:=ScrollContainer.new();outer.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;panel.add_child(outer)
	var body:=VBoxContainer.new();body.size_flags_horizontal=SIZE_EXPAND_FILL;body.add_theme_constant_override("separation",10);outer.add_child(body)
	var header:=HBoxContainer.new();body.add_child(header)
	label(header,"BROUGHT HOME",24,T.INK)
	var exit:=Button.new();exit.text="×";exit.custom_minimum_size=Vector2(40,38);exit.pressed.connect(close);header.add_child(exit)
	label(body,"OBJECTS · KNOWLEDGE · CULTURE",11,T.GOLD)
	summary=label(body,"",13,T.TEXT_SOFT)
	var policies:=VBoxContainer.new();policies.add_theme_constant_override("separation",6);body.add_child(policies)
	choice(policies,"New households",["balanced","welcome","consolidate"],["As capacity allows","Welcome faster","Consolidate at home"],String(E.data().migration_policy),func(value:String):E.policy(value,String(E.data().sharing_policy));refresh(true))
	choice(policies,"Our knowledge",["open","selective","guarded"],["Share practices openly","Share culture & simple crafts","Keep our know-how private"],String(E.data().sharing_policy),func(value:String):E.policy(String(E.data().migration_policy),value);refresh(true))
	filter=OptionButton.new();filter.add_item("All returned finds");filter.add_item("Objects & specimens");filter.add_item("Knowledge");filter.add_item("Culture");filter.item_selected.connect(func(_value:int):page=0;refresh(true));body.add_child(filter)
	search=LineEdit.new();search.placeholder_text="Search artifacts and origins";search.text_changed.connect(func(_text:String):page=0;refresh(true));body.add_child(search)
	var pages:=HBoxContainer.new();body.add_child(pages)
	for direction:int in [-1,1]:
		var button:=Button.new();button.text="Previous" if direction<0 else "Next 40";button.pressed.connect(func():page=maxi(0,page+direction);refresh(true));pages.add_child(button)
	cards=VBoxContainer.new();cards.size_flags_horizontal=SIZE_EXPAND_FILL;cards.add_theme_constant_override("separation",8);body.add_child(cards)
	label(body,"Knowledge workers examine finds automatically using 15% of their existing effort. Understanding a practice still leaves its ordinary research, materials and adoption requirements.",12,T.MUTED)
	resized.connect(layout);layout();refresh(true)
func choice(parent:Node,caption:String,ids:Array,titles:Array,current:String,action:Callable)->void:
	var row:=VBoxContainer.new();parent.add_child(row);label(row,caption,13,T.BODY)
	var select:=OptionButton.new();select.custom_minimum_size.y=32;select.size_flags_horizontal=SIZE_EXPAND_FILL
	for index in ids.size():select.add_item(titles[index]);select.set_item_metadata(index,ids[index])
	select.select(maxi(0,ids.find(current)));select.item_selected.connect(func(index:int):action.call(String(select.get_item_metadata(index))));row.add_child(select)
func layout()->void:
	if not is_instance_valid(panel):return
	panel.size=Vector2(minf(690,size.x-24),maxf(160,minf(800,size.y-24)));panel.position=(size-panel.size)*.5
func _unhandled_key_input(event:InputEvent)->void:
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:close();get_viewport().set_input_as_handled()
func _process(delta:float)->void:
	timer+=delta
	if timer>=1:timer=0;refresh(false)
func refresh(force:bool)->void:
	var state:=E.data();var pressure:=E.pressure()
	var sig:=str([state.collections.size(),state.history.size(),int(pressure.unsettled),int(GameState.elapsed_days),filter.selected])
	if not force and sig==signature:return
	signature=sig
	summary.text="%d finds · %d people settling in · room to invite %d" % [state.collections.size(),ceili(float(pressure.unsettled)),E.reception_capacity()]
	var collection:=A.summary()
	summary.text+="\n%d artifacts · %.1f prestige · science +%.1f%% · culture research +%.1f%%\nMuseum income last turn: %.2f" % [collection.count,collection.prestige,collection.science*100,collection.culture*100,E.data().get("museum_revenue",0)]
	for child in cards.get_children():cards.remove_child(child);child.queue_free()
	var values:Array=state.collections.values();values.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return int(a.returned_day)>int(b.returned_day) if a.returned_day!=b.returned_day else String(a.id)<String(b.id))
	var shown:=0
	var matches:Array[Dictionary]=[]
	for item:Dictionary in values:
		if filter.selected==1 and item.kind not in ["artifact","specimen"]:continue
		if filter.selected==2 and item.kind!="knowledge":continue
		if filter.selected==3 and item.kind!="culture":continue
		if not search.text.is_empty() and not (String(item.name)+" "+String(item.source_name)).to_lower().contains(search.text.to_lower()):continue
		matches.append(item)
	page=mini(page,maxi(0,(matches.size()-1)/40))
	summary.text+=" · Page %d of %d" % [page+1,maxi(1,ceili(matches.size()/40.0))]
	for item:Dictionary in matches.slice(page*40,(page+1)*40):
		var card:=PanelContainer.new();card.add_theme_stylebox_override("panel",T.flat(T.TILE_BG,T.TEAL if float(item.study)>=1 else T.BORDER,1,6,12));cards.add_child(card)
		var row:=HBoxContainer.new();row.add_theme_constant_override("separation",12);card.add_child(row)
		var icon:=TextureRect.new();icon.texture=V.icon("population" if item.kind=="culture" else "production" if item.kind in ["artifact","specimen"] else "logistics");icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.custom_minimum_size=Vector2(36,36);row.add_child(icon)
		var content:=VBoxContainer.new();content.size_flags_horizontal=SIZE_EXPAND_FILL;row.add_child(content)
		var artwork:=ArtifactArt.texture(item)
		if artwork!=null:
			icon.visible=false
			var illustration:=TextureRect.new();illustration.texture=artwork;illustration.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;illustration.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;illustration.custom_minimum_size.y=240;illustration.size_flags_horizontal=SIZE_EXPAND_FILL;content.add_child(illustration)
		label(content,"PREHISTORIC FIND" if item.get("artifact_origin","")=="prehistoric" else "CIVILIZATION-MADE" if item.get("artifact_origin","")=="civilization" else String(item.kind).to_upper(),10,T.GOLD);label(content,String(item.name),18,T.INK)
		label(content,"%s · encountered day %d · home day %d" % [item.source_name,int(item.observed_day),int(item.returned_day)],12,T.TEXT_SOFT)
		var bar:=ProgressBar.new();bar.show_percentage=false;bar.value=float(item.study)*100;bar.custom_minimum_size.y=6;content.add_child(bar)
		var definition:=DiscoverySystem.discovery_definition(String(item.discovery_id))
		var known:=String(item.discovery_id) in GameState.known_discoveries
		label(content,"Recorded in our cultural and knowledge collection" if known else ("Evidence ready: "+String(definition.get("name","related investigation")) if float(item.study)>=1 else "Being examined · %d%%" % roundi(float(item.study)*100)),12,T.TEAL)
		if float(item.study)>=1 and not known:
			var button:=Button.new();button.text="Direct study: "+String(definition.get("name","investigation"));button.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
			button.disabled=not DiscoverySystem._discovery_is_eligible(definition,int(GameState.elapsed_days)) if not definition.is_empty() else true
			var needs:Array[String]=[]
			if button.disabled:
				for requirement:Dictionary in definition.get("resource_requirements",[]):
					if not DiscoverySystem._resource_requirements_met([requirement]):needs.append(String(requirement.resource)+" ("+String(requirement.stage)+")")
				if needs.is_empty():needs.append("supporting discoveries and local conditions")
				label(content,"Needs: "+", ".join(needs),12,T.GOLD)
			button.tooltip_text="Uses the existing research team; materials and foundations still apply."
			button.pressed.connect(func():
				var result:=DiscoverySystem.select_research_target(String(item.discovery_id))
				if result.has("error"):summary.text=String(result.error)
				else:summary.text="Research directed toward "+String(definition.name))
			content.add_child(button)
		if item.kind=="artifact":artifact_actions(content,item)
		shown+=1
		if shown>=40:break
	if shown==0:label(cards,"Explorers bring back samples from ground they visit. Peaceful encounters can bring objects, accounts and cultural practices. Finds appear here only when their carriers return.",15,T.TEXT_SOFT)
	if not state.history.is_empty():label(cards,String(state.history[0].text),12,T.TEXT_SOFT)

func artifact_actions(content:Node,item:Dictionary)->void:
	label(content,"%s · %.1f prestige · value %.2f · held %.1f years" % [A.TIERS[int(item.get("rarity",0))],A.prestige(item),A.price(item),float(item.get("held_days",0))/360],12,T.GOLD)
	var display:=Button.new();display.text="Return to archive" if item.get("exhibited",false) else "Exhibit in museum";display.disabled=not A.museum_ready();display.tooltip_text="Requires public libraries and comparative chronicles. Studied exhibits attract paying visitors once currency is available.";display.pressed.connect(func():A.exhibit(String(item.id));refresh(true));content.add_child(display)
	var recipient:=OptionButton.new();recipient.fit_to_longest_item=false;recipient.clip_text=true;recipient.add_item("Choose a contacted civilization");recipient.set_item_metadata(0,"");content.add_child(recipient)
	for id:String in E.data().connections:
		if E.owner_state(id)==null or id=="player":continue
		recipient.add_item(E.owner_state(id).settlement_name);recipient.set_item_metadata(recipient.item_count-1,id)
	var requested:=OptionButton.new();requested.fit_to_longest_item=false;requested.clip_text=true;requested.add_item("Choose an artifact to receive");requested.set_item_metadata(0,"");content.add_child(requested)
	var requested_search:=LineEdit.new();requested_search.placeholder_text="Search their artifacts";content.add_child(requested_search)
	var populate:=func(index:int):
		requested.clear();requested.add_item("Choose an artifact to receive");requested.set_item_metadata(0,"")
		var target:=E.owner_state(String(recipient.get_item_metadata(index)))
		if target==null:return
		for other:Dictionary in target.society_exchange.collections.values():
			if other.kind!="artifact":continue
			if not requested_search.text.is_empty() and not String(other.name).to_lower().contains(requested_search.text.to_lower()):continue
			requested.add_item("%s (%.2f)" % [other.name,A.price(other)]);requested.set_item_metadata(requested.item_count-1,other.id)
			if requested.item_count>=41:break
	recipient.item_selected.connect(populate)
	requested_search.text_changed.connect(func(_text:String):populate.call(recipient.selected))
	for mode:String in ["gift","sell","trade"]:
		var action:=Button.new();action.text=mode.capitalize();action.pressed.connect(func():
			var result:=A.transfer(String(item.id),String(recipient.get_item_metadata(recipient.selected)),mode,String(requested.get_item_metadata(requested.selected)))
			if result.has("error"):summary.text=String(result.error)
			else:refresh(true));content.add_child(action)
