extends Control
const T=preload("res://scripts/hud/hud_tokens.gd")
const INTEL=preload("res://scripts/city_intelligence.gd")
var city_id:=""
var civ_id:=""
var selector:OptionButton
var duration:OptionButton
var costs:Label
var send:Button
var title:Label
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
	var button:=Button.new();button.text=text;button.custom_minimum_size.y=36;button.add_theme_font_size_override("font_size",14)
	var style:=StyleBoxFlat.new();style.bg_color=T.GOLD_WASH if primary else T.BUTTON_BG;style.border_color=T.GOLD if primary else T.BORDER;style.set_border_width_all(1);style.set_corner_radius_all(4)
	button.add_theme_stylebox_override("normal",style);button.pressed.connect(callback);parent.add_child(button);return button
func _ready()->void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter=MOUSE_FILTER_IGNORE
	var background:=ColorRect.new();background.color=Color("090f11");background.set_anchors_and_offsets_preset(PRESET_RIGHT_WIDE);background.offset_left=-420;add_child(background)
	var margin:=MarginContainer.new();margin.set_anchors_and_offsets_preset(PRESET_RIGHT_WIDE);margin.offset_left=-420;add_child(margin)
	for edge in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+edge,24)
	var root:=VBoxContainer.new();root.add_theme_constant_override("separation",12);margin.add_child(root)
	var top:=HBoxContainer.new();root.add_child(top)
	var eyebrow:=_label(top,"CITY ENCOUNTER",13,T.GOLD);eyebrow.size_flags_horizontal=SIZE_EXPAND_FILL
	_button(top,"RETURN TO MAP",_close)
	title=_label(root,"Settlement report",28,T.INK)
	selector=OptionButton.new();selector.fit_to_longest_item=false;selector.custom_minimum_size.y=34;root.add_child(selector)
	for city:Dictionary in CivilizationSystem.city_intelligence.known_cities("player",civ_id):
		selector.add_item(String(city.name));selector.set_item_metadata(selector.item_count-1,String(city.city_id))
		if city.city_id==city_id:selector.select(selector.item_count-1)
	selector.item_selected.connect(func(_i:int):refresh())
	var banner:=_box(root);summary=_label(banner,"",18,T.GOLD);provenance=_label(banner,"",13,T.TEXT_SOFT)
	var body:=HBoxContainer.new();body.add_theme_constant_override("separation",18);body.size_flags_vertical=SIZE_EXPAND_FILL;root.add_child(body)
	var left:=VBoxContainer.new();left.visible=false;left.size_flags_horizontal=SIZE_EXPAND_FILL;left.add_theme_constant_override("separation",10);body.add_child(left)
	control_label=_label(left,"",14,T.TEXT_SOFT)
	var grid:=GridContainer.new();grid.columns=2;grid.add_theme_constant_override("h_separation",10);grid.add_theme_constant_override("v_separation",10);left.add_child(grid)
	for key:String in INTEL.FIELDS:
		var card:=_box(grid);_label(card,String(INTEL.FIELDS[key].label).to_upper(),11,T.TEXT_SOFT)
		cards[key]={"value":_label(card,"Unknown",19,T.INK),"note":_label(card,"Not observed",12,T.MUTED)}
	var stores:=_box(grid);_label(stores,"DEPOSITS & STORES",11,T.TEXT_SOFT);_label(stores,"Not surveyed",19,T.INK);_label(stores,"Individual stores remain unknown.",12,T.MUTED)
	var right:=VBoxContainer.new();right.custom_minimum_size.x=0;right.size_flags_horizontal=SIZE_EXPAND_FILL;right.add_theme_constant_override("separation",12);body.add_child(right)
	_button(right,"SHOW THIS CITY ON MAP",_show_map,true)
	_button(root,"CITY INTELLIGENCE / ORDERS",func():left.visible=not left.visible;right.visible=not left.visible)
	var tabs:=TabContainer.new();tabs.size_flags_vertical=SIZE_EXPAND_FILL;right.add_child(tabs)
	var recon:=VBoxContainer.new();recon.name="Reconnaissance";recon.add_theme_constant_override("separation",12);tabs.add_child(recon)
	_label(recon,"Bring back better evidence",20,T.INK)
	_label(recon,"Scouts must travel, observe, and return before this report changes.",14,T.TEXT_SOFT)
	duration=OptionButton.new();duration.custom_minimum_size.y=36;recon.add_child(duration)
	for days:int in CivilizationSystem.SCOUT_DURATIONS:duration.add_item("%d-day reconnaissance" % days);duration.set_item_metadata(duration.item_count-1,days)
	duration.item_selected.connect(func(_i:int):refresh())
	costs=_label(recon,"",14,T.BODY)
	send=_button(recon,"SEND SCOUTS",_send_scouts,true)
	var military:=VBoxContainer.new();military.name="Military";military.add_theme_constant_override("separation",10);tabs.add_child(military)
	_label(military,"Approach this settlement",20,T.INK)
	army_choice=OptionButton.new();army_choice.fit_to_longest_item=false;army_choice.custom_minimum_size.y=34;military.add_child(army_choice)
	for force:Dictionary in MilitaryCampaign.field_armies:
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
		for force:Dictionary in MilitaryCampaign.occupation_forces:
			if String(force.get("region_id",""))==city_id:_close();preload("res://scripts/hud/occupation_view.gd").open(String(force.civ_id),city_id);return)
	aftermath_button=_button(military,"REVIEW BATTLE AFTERMATH",func():
		var scene:=get_tree().current_scene
		if scene and scene.has_method("_open_war_planning"):_close();scene._open_war_planning())

	if army_choice.item_count>0 or not MilitaryCampaign.pending_aftermath.is_empty():tabs.current_tab=1
	feedback=_label(root,"Estimates describe returned observations. Conditions may have changed.",13,T.TEXT_SOFT)
	var world:=CityEncounterWorld.terrain(get_tree().root)
	var known:Dictionary=CivilizationSystem.city_intelligence.known("player",city_id)
	if world!=null and not known.is_empty() and MilitaryCampaign.active_engagement.is_empty():
		world.camera.size=maxf(.22,preload("res://scripts/foreign_settlement_visual.gd").framing_size(known))
		world._set_camera_target(Vector3(known.position.x,0,known.position.z));world._refresh_contact_encounter_markers()
	refresh()
func _close()->void:get_parent().queue_free()
func _show_map()->void:
	var scene:=get_tree().current_scene
	if scene and scene.has_method("_focus_known_city"):scene._focus_known_city(city_id)
func _send_scouts()->void:
	var result:=CivilizationSystem.dispatch_scouts(int(duration.get_selected_metadata()),"city:"+city_id)
	feedback.text=String(result.get("error","Scouts departed. Evidence will update after their return."));refresh()
func _march()->void:
	if army_choice.item_count==0:return
	var result:=MilitaryCampaign.move_field_army(int(army_choice.get_selected_metadata()),city_id)
	feedback.text=String(result.get("error",result.get("message","Movement ordered.")));refresh()
func _diplomacy()->void:
	var city:Dictionary=CivilizationSystem.city_intelligence.known("player",city_id)
	var owner:=String(city.get("controller",""));if owner=="":owner=String(city.get("civ_id",""))
	if owner=="":feedback.text="The polity has not been identified. Return a better report first.";return
	var scene:=get_tree().current_scene
	if scene and scene.has_method("_open_civilizations_panel"):
		scene.selected_civilization_id=owner;scene.selected_civilization_region_id=city_id;_close();scene._open_civilizations_panel()
func _operate(besiege:bool)->void:
	if not MilitaryCampaign.active_siege.is_empty() and String(MilitaryCampaign.active_siege.region_id)==city_id:
		_close();preload("res://scripts/hud/siege_screen.gd").open();return
	if not MilitaryCampaign.active_engagement.is_empty():
		_close();MilitaryCommandUI._open_battle_graphics();return
	var city:Dictionary=CivilizationSystem.city_intelligence.known("player",city_id)
	var owner:=String(city.get("controller",""));if owner=="":owner=String(city.get("civ_id",""))
	var chosen:=int(army_choice.get_selected_metadata()) if army_choice.item_count>0 else -1
	var result:=MilitaryCampaign.order_city_operation(chosen,owner,city_id,besiege)
	if result.has("error"):feedback.text=String(result.error);refresh();return
	if bool(result.get("queued",false)):feedback.text=String(result.message);_close();return
	var scene:=get_tree().current_scene
	_close()
	if besiege:preload("res://scripts/hud/siege_screen.gd").open()
	elif not MilitaryCampaign.active_engagement.is_empty():MilitaryCommandUI.call_deferred("_open_battle_graphics")
func refresh()->void:
	if selector.item_count==0:
		title.text="No reported settlements";summary.text="A returned report must first identify a city.";send.disabled=true;march.disabled=true;attack.disabled=true;siege.disabled=true;return
	city_id=String(selector.get_selected_metadata())
	var city:Dictionary=CivilizationSystem.city_intelligence.known("player",city_id)
	title.text=String(city.name).trim_prefix("Reported home of ").capitalize()
	var fields:Dictionary=city.fields
	var age:=int(city.get("age_days",-1))
	summary.text=("Location reported · interior unobserved" if fields.is_empty() else "%d of 7 city estimates reported" % fields.size())+"  /  "+("Observation date unknown" if age<0 else "%d days since observation" % age)
	var source:=String(city.source)
	if source=="legacy or returned home location":source="Earlier home-location report"
	provenance.text="%s · Received day %d · %s" % [source,int(city.reported_day),String(city.freshness).capitalize()]
	provenance.tooltip_text="Source: %s\nReference: %s\nObserved day: %d" % [String(city.source),String(city.reference),int(city.observed_day)]
	control_label.text="LAST REPORTED CONTROL  ·  "+CivilizationSystem.city_intelligence.controller_label(String(city.controller))
	for key:String in cards:
		var field:Dictionary=fields.get(key,{})
		var value:Label=cards[key].value;var note:Label=cards[key].note
		value.text="Unknown";note.text="Not observed"
		if not field.is_empty():
			var scale:=100.0 if INTEL.FIELDS[key].unit=="capacity" else 1.0
			value.text="%s–%s %s" % [str(roundi(float(field.low)*scale)),str(roundi(float(field.high)*scale)),"%" if scale>1 else String(INTEL.FIELDS[key].unit)]
			note.text="Observed day %d%s" % [int(field.observed_day)," · stale" if bool(field.get("stale",false)) else ""]
	var quote:=CivilizationSystem.scout_mission_quote(int(duration.get_selected_metadata()),"city:"+city_id)
	send.disabled=not bool(quote.get("can_dispatch",false))
	costs.text=String(quote.get("error",quote.get("blocker",""))) if send.disabled else "%d scouts · %.1f food\n%d days planned" % [int(quote.personnel),float(quote.provisions),int(quote.duration_days)]
	var owner:=String(city.controller);if owner=="":owner=String(city.civ_id)
	var owner_index:=CivilizationSystem._civilization_index(owner)
	if owner_index>=0:
		var relation:Dictionary=CivilizationSystem.civilizations[owner_index].player_relation
		control_label.text+="  /  "+("AT WAR" if bool(relation.get("at_war",false)) else "AT PEACE · attacking starts a war")
	var chosen:=int(army_choice.get_selected_metadata()) if army_choice.item_count>0 else -1
	var availability:=MilitaryCampaign.city_operation_quote(chosen,owner,city_id)
	attack.disabled=availability.has("error");siege.disabled=attack.disabled
	var same_siege:=not MilitaryCampaign.active_siege.is_empty() and String(MilitaryCampaign.active_siege.region_id)==city_id
	if same_siege:attack.disabled=false;siege.disabled=false
	garrison_button.visible=false
	for force:Dictionary in MilitaryCampaign.occupation_forces:
		if String(force.get("region_id",""))==city_id and int(force.get("troops",0))>0:garrison_button.visible=true
	aftermath_button.visible=not MilitaryCampaign.pending_aftermath.is_empty()
	attack.visible=not garrison_button.visible;siege.visible=not garrison_button.visible

	var here:=bool(availability.get("at_target",false))
	attack.text="ATTACK NOW" if here else "MARCH & ATTACK"
	siege.text="BESIEGE NOW" if here else "MARCH & BESIEGE"
	military_note.text=String(availability.get("error","Army is at this city. Your order starts hostilities immediately." if here else "Approach takes about %d days. Hostilities begin on arrival." % int(availability.get("days",0))))

	if same_siege:attack.text="RETURN TO SIEGE";siege.visible=false;military_note.text="Your army is maintaining this siege. Return to its orders and supply situation."
	if garrison_button.visible:military_note.text=MilitaryCampaign.city_force_summary(city_id)

func _process(delta:float)->void:
	timer+=delta
	if timer>=5:timer=0;refresh()
func _unhandled_input(event:InputEvent)->void:
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:_close();get_viewport().set_input_as_handled()
