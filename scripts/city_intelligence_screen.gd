extends Control
const T=preload("res://scripts/hud/hud_tokens.gd")
const V=preload("res://scripts/hud/city_report_visuals.gd")
const IDENTITY=preload("res://scripts/city_map_identity.gd")
const INTEL=preload("res://scripts/city_intelligence.gd")
var city_id:=""
var civ_id:=""
var selector:OptionButton
var duration:OptionButton
var costs:Label
var send:Button
var title:Label
var flag:TextureRect
var panel:PanelContainer
var tabs:TabContainer
var detail_text:Label
var projection:Label
var provenance_button:Button
var grid:GridContainer
var journey:HBoxContainer
var journey_values:Array[Label]=[]
var scouting_hint:Label
var summary:Label
var provenance:Label
var control_label:Label
var army_choice:OptionButton
var military_note:Label
var feedback:Label
var march:Button
var attack:Button
var siege:Button
var garrison_button:Button
var aftermath_button:Button
var cards:Dictionary={}
var timer:=0.0

func _label(parent:Node,text:String,size:int=15,color:Color=T.BODY)->Label:
	var label:=Label.new();label.text=text;label.add_theme_font_size_override("font_size",size);label.add_theme_color_override("font_color",color)
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;parent.add_child(label);return label
func _box(parent:Node)->VBoxContainer:
	var panel:=PanelContainer.new();panel.size_flags_horizontal=SIZE_EXPAND_FILL;parent.add_child(panel)
	var style:=StyleBoxFlat.new();style.bg_color=T.TILE_BG;style.border_color=T.BORDER;style.set_border_width_all(1);style.set_corner_radius_all(5)
	style.content_margin_left=16;style.content_margin_right=16;style.content_margin_top=8;style.content_margin_bottom=8;panel.add_theme_stylebox_override("panel",style)
	var box:=VBoxContainer.new();box.add_theme_constant_override("separation",5);panel.add_child(box);return box
func _button(parent:Node,text:String,callback:Callable,primary:bool=false)->Button:
	var button:=Button.new();button.text=text;button.clip_text=true;button.size_flags_horizontal=SIZE_EXPAND_FILL;button.custom_minimum_size.y=34;button.add_theme_font_size_override("font_size",13)
	var style:=T.flat(T.GOLD_WASH if primary else T.BUTTON_BG,T.GOLD if primary else T.BORDER,1,5)
	style.content_margin_left=10;style.content_margin_right=10
	button.add_theme_stylebox_override("normal",style)
	var hover:=style.duplicate();hover.bg_color=T.HOVER_BG;hover.border_color=T.GOLD if primary else T.TEAL
	button.add_theme_stylebox_override("hover",hover);button.add_theme_stylebox_override("pressed",hover)
	button.add_theme_stylebox_override("focus",T.flat(Color.TRANSPARENT,T.TEAL,1,5))
	button.add_theme_font_size_override("font_size",13)
	button.pressed.connect(callback);parent.add_child(button);return button

func _metric(parent:Node,key:String,hero:bool=false)->void:
	var card:=_box(parent);card.add_theme_constant_override("separation",3)
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",8);card.add_child(row)
	var icon:=TextureRect.new();icon.texture=V.icon(key);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.custom_minimum_size=Vector2(22,22);row.add_child(icon)
	var label:=_label(row,String(V.LABELS[key]),12,T.TEXT_SOFT);label.size_flags_horizontal=SIZE_EXPAND_FILL
	var value:=_label(card,"Unknown",30 if hero else 20,T.INK)
	var note:=_label(card,"Not observed",11,T.MUTED)
	cards[key]={"value":value,"note":note,"card":card}
	if key in ["fortification","production","logistics","damage"]:
		var band:=V.Band.new();band.ink=V.COLORS[key];card.add_child(band);cards[key]["band"]=band
	if hero:
		projection=_label(card,"",12,T.TEXT_SOFT)

func _layout()->void:
	if not is_instance_valid(panel):return
	var width:=minf(448,maxf(280,size.x-16))
	panel.offset_left=-width-8;panel.offset_right=-8
	panel.offset_top=8;panel.offset_bottom=-8
	grid.columns=2 if width>=350 else 1

func _page(tabs:TabContainer,caption:String)->VBoxContainer:
	var scroll:=ScrollContainer.new();scroll.name=caption
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	tabs.add_child(scroll)
	var box:=VBoxContainer.new();box.size_flags_horizontal=SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation",10);scroll.add_child(box)
	return box

func _ready()->void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter=MOUSE_FILTER_IGNORE
	# A map click dismisses this sheet and is consumed before map orders run.
	var dismiss:=Control.new();dismiss.set_anchors_and_offsets_preset(PRESET_FULL_RECT);add_child(dismiss)
	dismiss.gui_input.connect(func(event:InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:dismiss.accept_event();_close())
	panel=PanelContainer.new();panel.set_anchors_and_offsets_preset(PRESET_RIGHT_WIDE);add_child(panel)
	var shell:=T.flat(Color("0b1418"),T.BORDER_2,1,10)
	shell.content_margin_left=16;shell.content_margin_right=16;shell.content_margin_top=12;shell.content_margin_bottom=12
	panel.add_theme_stylebox_override("panel",shell)
	var root:=VBoxContainer.new();root.add_theme_constant_override("separation",8);panel.add_child(root)
	var top:=HBoxContainer.new();root.add_child(top)
	var eyebrow:=_label(top,"SETTLEMENT  /  INTELLIGENCE",11,T.GOLD);eyebrow.size_flags_horizontal=SIZE_EXPAND_FILL
	var close:=_button(top,"×",_close);close.name="Close";close.clip_text=false;close.size_flags_horizontal=SIZE_SHRINK_END;close.custom_minimum_size=Vector2(30,28);close.tooltip_text="Close · Escape or click the map";close.add_theme_font_size_override("font_size",22)
	var identity:=HBoxContainer.new();identity.add_theme_constant_override("separation",10);root.add_child(identity)
	flag=TextureRect.new();flag.custom_minimum_size=Vector2(52,44);flag.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;flag.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;identity.add_child(flag)
	var names:=VBoxContainer.new();names.size_flags_horizontal=SIZE_EXPAND_FILL;names.add_theme_constant_override("separation",0);identity.add_child(names)
	selector=OptionButton.new();selector.fit_to_longest_item=false;selector.clip_text=true;selector.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;selector.custom_minimum_size.y=34;selector.add_theme_font_size_override("font_size",24);selector.add_theme_color_override("font_color",T.INK)
	selector.add_theme_stylebox_override("normal",T.flat(Color.TRANSPARENT,Color.TRANSPARENT,0,4));selector.add_theme_stylebox_override("hover",T.flat(T.HOVER_BG,Color.TRANSPARENT,0,4));names.add_child(selector)
	title=_label(names,"",14,T.INK);title.hide()
	control_label=_label(names,"",12,T.TEXT_SOFT)
	for city:Dictionary in WorldSimulation.world.city_intelligence.known_cities("player",civ_id):
		selector.add_item(String(city.name));selector.set_item_metadata(selector.item_count-1,String(city.city_id))
		if city.city_id==city_id:selector.select(selector.item_count-1)
	selector.item_selected.connect(func(_i:int):refresh())
	var ribbon:=HBoxContainer.new();root.add_child(ribbon)
	summary=_label(ribbon,"",12,T.AMBER);summary.size_flags_horizontal=SIZE_EXPAND_FILL
	provenance=_label(ribbon,"",11,T.MUTED);provenance.autowrap_mode=TextServer.AUTOWRAP_OFF;provenance.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	var badge:=T.flat(T.GOLD_WASH,Color.TRANSPARENT,0,4);badge.content_margin_left=8;badge.content_margin_right=8;badge.content_margin_top=4;badge.content_margin_bottom=4;provenance.add_theme_stylebox_override("normal",badge)
	tabs=TabContainer.new();tabs.size_flags_vertical=SIZE_EXPAND_FILL;root.add_child(tabs)
	tabs.add_theme_stylebox_override("panel",StyleBoxEmpty.new())
	for state in ["tab_selected","tab_unselected","tab_hovered"]:
		var style:=T.flat(T.ACTIVE_BG if state=="tab_selected" else Color.TRANSPARENT,Color.TRANSPARENT,0,4)
		style.content_margin_left=14;style.content_margin_right=14;style.content_margin_top=8;style.content_margin_bottom=8
		if state=="tab_selected":style.border_color=T.GOLD;style.border_width_bottom=2
		tabs.add_theme_stylebox_override(state,style)
	tabs.add_theme_font_size_override("font_size",13)
	var left:=_page(tabs,"Overview")
	_metric(left,"population",true)
	grid=GridContainer.new();grid.columns=2;grid.size_flags_horizontal=SIZE_EXPAND_FILL;grid.add_theme_constant_override("h_separation",8);grid.add_theme_constant_override("v_separation",8);left.add_child(grid)
	for key:String in ["garrison","fortification","supply","production","logistics","damage"]:_metric(grid,key)
	provenance_button=_button(left,"Report details  ›",func():detail_text.visible=not detail_text.visible)
	detail_text=_label(left,"",12,T.TEXT_SOFT);detail_text.hide()
	var actions:=HBoxContainer.new();left.add_child(actions)
	_button(actions,"Focus on map",_show_map)
	_button(actions,"Refresh intelligence",func():tabs.current_tab=1,true)
	var recon:=_page(tabs,"Scouting")
	_label(recon,"Request a fresh report",18,T.INK)
	_label(recon,"Scouts must travel, observe, and return before this report changes.",14,T.TEXT_SOFT)
	duration=OptionButton.new();duration.custom_minimum_size.y=36;recon.add_child(duration)
	for days:int in CivilizationSystem.SCOUT_DURATIONS:duration.add_item("%d-day reconnaissance" % days);duration.set_item_metadata(duration.item_count-1,days)
	duration.item_selected.connect(func(_i:int):refresh())
	journey=HBoxContainer.new();journey.add_theme_constant_override("separation",6);recon.add_child(journey)
	for caption:String in ["OUTBOUND","OBSERVING","RETURN"]:
		var cell:=_box(journey);_label(cell,caption,10,T.TEAL if caption=="OBSERVING" else T.MUTED)
		journey_values.append(_label(cell,"",20,T.INK))
	scouting_hint=_label(recon,"Longer stays sharpen the population count. Travel days do not. Arrival and return can vary.",12,T.TEXT_SOFT)
	costs=_label(recon,"",14,T.BODY)
	send=_button(recon,"SEND SCOUTS",_send_scouts,true)
	var military:=_page(tabs,"Military")
	_label(military,"Approach this settlement",20,T.INK)
	army_choice=OptionButton.new();army_choice.fit_to_longest_item=false;army_choice.custom_minimum_size.y=34;military.add_child(army_choice)
	for force:Dictionary in WorldSimulation.military.field_armies:
		if int(force.get("troops",0))<=0:continue
		army_choice.add_item(String(force.name));army_choice.set_item_metadata(army_choice.item_count-1,int(force.army_id))
	var terrain_scene:=CityEncounterWorld.terrain(get_tree().root)
	if terrain_scene and "selected_army_id" in terrain_scene:
		for i in army_choice.item_count:
			if int(army_choice.get_item_metadata(i))==int(terrain_scene.selected_army_id):army_choice.select(i)
	army_choice.item_selected.connect(func(_i:int):refresh())
	march=_button(military,"MOVE ONLY",_march)
	march.visible=false
	_label(military,"Attack or besiege with one order. Your army approaches automatically if needed.",13,T.TEXT_SOFT)
	military_note=_label(military,"",14,T.AMBER)
	var combat_row:=HBoxContainer.new();military.add_child(combat_row)
	attack=_button(combat_row,"ATTACK",func():_operate(false));attack.size_flags_horizontal=SIZE_EXPAND_FILL
	siege=_button(combat_row,"BESIEGE",func():_operate(true));siege.size_flags_horizontal=SIZE_EXPAND_FILL
	_button(military,"DIPLOMACY",_diplomacy)
	garrison_button=_button(military,"MANAGE GARRISON",func():
		for force:Dictionary in WorldSimulation.military.occupation_forces:
			if String(force.get("region_id",""))==city_id:_close();preload("res://scripts/hud/occupation_view.gd").open(String(force.civ_id),city_id);return)
	aftermath_button=_button(military,"REVIEW BATTLE AFTERMATH",func():
		var scene:=get_tree().current_scene
		if scene and scene.has_method("_open_war_planning"):_close();scene._open_war_planning())

	tabs.current_tab=0
	feedback=_label(root,"",12,T.AMBER);feedback.hide()
	resized.connect(_layout);_layout()
	var world:=CityEncounterWorld.terrain(get_tree().root)
	var known:Dictionary=WorldSimulation.world.city_intelligence.known("player",city_id)
	if world!=null and not known.is_empty() and WorldSimulation.military.active_engagement.is_empty():
		world.camera.size=maxf(.22,preload("res://scripts/foreign_settlement_visual.gd").framing_size(known))
		world._set_camera_target(Vector3(known.position.x,0,known.position.z));world._refresh_contact_encounter_markers()
	refresh()
func _close()->void:get_parent().queue_free()
func _show_map()->void:
	var scene:=get_tree().current_scene
	if scene and scene.has_method("_focus_known_city"):scene._focus_known_city(city_id)
func _send_scouts()->void:
	var result:=WorldSimulation.world.dispatch_scouts(int(duration.get_selected_metadata()),"city:"+city_id)
	feedback.show();feedback.text=String(result.get("error","Scouts departed. Evidence will update after their return."));refresh()
func _march()->void:
	if army_choice.item_count==0:return
	var result:=WorldSimulation.military.move_field_army(int(army_choice.get_selected_metadata()),city_id)
	feedback.show();feedback.text=String(result.get("error",result.get("message","Movement ordered.")));refresh()
func _diplomacy()->void:
	var city:Dictionary=WorldSimulation.world.city_intelligence.known("player",city_id)
	var owner:=String(city.get("controller",""));if owner=="":owner=String(city.get("civ_id",""))
	if owner=="":feedback.show();feedback.text="The polity has not been identified. Return a better report first.";return
	var scene:=get_tree().current_scene
	if scene and scene.has_method("_open_civilizations_panel"):
		scene.selected_civilization_id=owner;scene.selected_civilization_region_id=city_id;_close();scene._open_civilizations_panel()
func _operate(besiege:bool)->void:
	if not WorldSimulation.military.active_siege.is_empty() and String(WorldSimulation.military.active_siege.region_id)==city_id:
		_close();preload("res://scripts/hud/siege_screen.gd").open();return
	if not WorldSimulation.military.active_engagement.is_empty():
		_close();MilitaryCommandUI._open_battle_graphics();return
	var city:Dictionary=WorldSimulation.world.city_intelligence.known("player",city_id)
	var owner:=String(city.get("controller",""));if owner=="":owner=String(city.get("civ_id",""))
	var chosen:=int(army_choice.get_selected_metadata()) if army_choice.item_count>0 else -1
	var result:=WorldSimulation.military.order_city_operation(chosen,owner,city_id,besiege)
	if result.has("error"):feedback.show();feedback.text=String(result.error);refresh();return
	if bool(result.get("queued",false)):feedback.show();feedback.text=String(result.message);_close();return
	var scene:=get_tree().current_scene
	_close()
	if besiege:preload("res://scripts/hud/siege_screen.gd").open()
	elif not WorldSimulation.military.active_engagement.is_empty():MilitaryCommandUI.call_deferred("_open_battle_graphics")
func refresh()->void:
	if selector.item_count==0:
		title.show();title.text="No reported settlements";summary.text="A returned report must first identify a city.";send.disabled=true;march.disabled=true;attack.disabled=true;siege.disabled=true;return
	city_id=String(selector.get_selected_metadata())
	var city:Dictionary=WorldSimulation.world.city_intelligence.known("player",city_id)
	title.text=String(city.name).trim_prefix("Reported home of ").capitalize()
	selector.tooltip_text=String(city.name)
	var fields:Dictionary=city.fields
	var age:=int(city.get("age_days",-1))
	summary.text=V.age_text(int(city.observed_day),int(WorldSimulation.state.elapsed_days))
	summary.add_theme_color_override("font_color",T.AMBER if age>180 else T.TEAL)
	provenance.text="STALE" if age>180 else "RECENT" if age<=30 and age>=0 else "AGING" if age>30 else "UNDATED"
	var source:=String(city.source)
	var observed_days:=int(city.get("observation_days",0))
	provenance_button.text="Report details  ·  %s  ›" % ("%d days observing" % observed_days if observed_days>0 else "earlier report")
	detail_text.text="%s\nObserved day %d · received day %d\n%s\nOriginal estimates are shown above. Projections allow for unobserved change; they do not track today's hidden population. Buildings on the map are representative, not a surveyed layout." % [source.capitalize(),int(city.observed_day),int(city.reported_day),"%d actual days observing this city. Travel days do not improve the count." % observed_days if observed_days>0 else "This earlier report did not record time observing the city."]
	detail_text.tooltip_text="Report reference: "+String(city.reference)
	var identity_id:=String(city.controller) if not String(city.controller).is_empty() else String(city.civ_id)
	flag.texture=IDENTITY.foreign(identity_id).texture
	control_label.text=WorldSimulation.world.city_intelligence.controller_label(String(city.controller))
	control_label.add_theme_color_override("font_color",IDENTITY.foreign(identity_id).color)
	for key:String in cards:
		var field:Dictionary=fields.get(key,{})
		var value:Label=cards[key].value;var note:Label=cards[key].note
		value.text=V.estimate(key,field)+( " residents" if key=="population" and not field.is_empty() else "")
		note.text="Not observed" if field.is_empty() else (("Last observed estimate" if key=="population" else "Last observed") if int(field.observed_day)==int(city.observed_day) else V.age_text(int(field.observed_day),int(WorldSimulation.state.elapsed_days)))
		note.visible=key=="population" or field.is_empty() or int(field.observed_day)!=int(city.observed_day)
		cards[key].card.tooltip_text=String(INTEL.FIELDS[key].label)+(" · capacity range on a 0–100% scale" if INTEL.FIELDS[key].unit=="capacity" else "")
		if cards[key].has("band"):cards[key].band.field=field;cards[key].band.queue_redraw()
	var pop:Dictionary=fields.get("population",{})
	projection.text="Unverified now: "+V.estimate("population",pop,false) if not pop.is_empty() and int(pop.get("age_days",0))>0 else ""
	if int(pop.get("age_days",0))>1095:projection.text="Current population unknown · new observation needed"
	projection.visible=not projection.text.is_empty()
	var quote:=WorldSimulation.world.scout_mission_quote(int(duration.get_selected_metadata()),"city:"+city_id)
	send.disabled=not bool(quote.get("can_dispatch",false))
	journey.visible=not send.disabled;scouting_hint.visible=not send.disabled
	if not send.disabled:
		journey_values[0].text="%dd" % int(quote.travel_leg_days);journey_values[1].text="%dd" % int(quote.observation_days);journey_values[2].text=journey_values[0].text
	costs.text=String(quote.get("error",quote.get("blocker",""))) if send.disabled else "%d scouts  ·  %.0f food  ·  %d days planned" % [int(quote.personnel),float(quote.provisions),int(quote.duration_days)]
	var owner:=String(city.controller);if owner=="":owner=String(city.civ_id)
	var owner_index:=WorldSimulation.world._civilization_index(owner)
	if owner_index>=0:
		var relation:Dictionary=WorldSimulation.world.civilizations[owner_index].player_relation
		control_label.text+="  ·  "+("At war" if bool(relation.get("at_war",false)) else "At peace")
	attack.tooltip_text="Attacking a city at peace starts a war on arrival.";siege.tooltip_text=attack.tooltip_text
	var chosen:=int(army_choice.get_selected_metadata()) if army_choice.item_count>0 else -1
	var availability:=WorldSimulation.military.city_operation_quote(chosen,owner,city_id)
	attack.disabled=availability.has("error");siege.disabled=attack.disabled
	var same_siege:=not WorldSimulation.military.active_siege.is_empty() and String(WorldSimulation.military.active_siege.region_id)==city_id
	if same_siege:attack.disabled=false;siege.disabled=false
	garrison_button.visible=false
	for force:Dictionary in WorldSimulation.military.occupation_forces:
		if String(force.get("region_id",""))==city_id and int(force.get("troops",0))>0:garrison_button.visible=true
	aftermath_button.visible=not WorldSimulation.military.pending_aftermath.is_empty()
	attack.visible=not garrison_button.visible;siege.visible=not garrison_button.visible

	var here:=bool(availability.get("at_target",false))
	attack.text="ATTACK NOW" if here else "MARCH & ATTACK"
	siege.text="BESIEGE NOW" if here else "MARCH & BESIEGE"
	military_note.text=String(availability.get("error","Army is at this city. Your order starts hostilities immediately." if here else "Approach takes about %d days. Hostilities begin on arrival." % int(availability.get("days",0))))

	if same_siege:attack.text="RETURN TO SIEGE";siege.visible=false;military_note.text="Your army is maintaining this siege. Return to its orders and supply situation."
	if garrison_button.visible:military_note.text=WorldSimulation.military.city_force_summary(city_id)

func _process(delta:float)->void:
	timer+=delta
	if timer>=5:timer=0;refresh()
func _unhandled_input(event:InputEvent)->void:
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:_close();get_viewport().set_input_as_handled()
