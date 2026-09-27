extends Control
## The report on a foreign city: what our scouts saw, when, and who to talk to
## about it. It gives no orders of its own. Talking to their ruler or to our
## war leader happens in the court; watching the city belongs to the scouts.
const T=preload("res://scripts/hud/hud_tokens.gd")
const V=preload("res://scripts/hud/city_report_visuals.gd")
const P=preload("res://scripts/hud/paper_sheet.gd")
const When=preload("res://scripts/hud/report_when.gd")
const Orders=preload("res://scripts/hud/city_watch_orders.gd")
const IDENTITY=preload("res://scripts/city_map_identity.gd")
const INTEL=preload("res://scripts/city_intelligence.gd")
var city_id:=""
var civ_id:=""
var selector:OptionButton
var flag:TextureRect
var panel:PanelContainer
var title:Label
var control_label:Label
var summary:Label
var projection:Label
var grid:GridContainer
var detail_button:Button
var detail_text:Label
var talk_ruler:Button
var talk_general:Button
var scouting_box:VBoxContainer
var war_box:VBoxContainer
var siege_button:Button
var garrison_button:Button
var aftermath_button:Button
var feedback:Label
var cards:Dictionary={}
var timer:=0.0
var _scouting_signature:=""
var _war_signature:=""

func _metric(parent:Node,key:String,hero:bool=false)->void:
	var card:=P.card(parent)
	card.add_theme_constant_override("separation",2)
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",8);card.add_child(row)
	var icon:=TextureRect.new();icon.texture=V.icon(key);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.custom_minimum_size=Vector2(20,20);row.add_child(icon)
	var name:=P.label(row,V.label(key),"small",T.INK_MUTED);name.size_flags_horizontal=SIZE_EXPAND_FILL
	var value:=P.label(card,"Not seen","value" if not hero else "voice",T.INK)
	var note:=P.label(card,String(V.MEANINGS.get(key,"")),"small",T.INK_MUTED)
	cards[key]={"value":value,"note":note,"card":card.get_parent(),"name":name}
	if hero:projection=P.label(card,"","small",T.BODY)

func _layout()->void:
	if not is_instance_valid(panel):return
	var width:=minf(460,maxf(280,size.x-16))
	panel.offset_left=-width-8;panel.offset_right=-8
	panel.offset_top=8;panel.offset_bottom=-8
	grid.columns=2 if width>=366 else 1

func _ready()->void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter=MOUSE_FILTER_IGNORE
	theme=T.control_theme()
	# A map click dismisses this sheet and is consumed before map orders run.
	var dismiss:=Control.new();dismiss.set_anchors_and_offsets_preset(PRESET_FULL_RECT);add_child(dismiss)
	dismiss.gui_input.connect(func(event:InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:dismiss.accept_event();_close())
	panel=PanelContainer.new();panel.set_anchors_and_offsets_preset(PRESET_RIGHT_WIDE);add_child(panel)
	panel.add_theme_stylebox_override("panel",P.sheet_style(16))
	var root:=VBoxContainer.new();root.add_theme_constant_override("separation",8);panel.add_child(root)
	var top:=HBoxContainer.new();root.add_child(top)
	var eyebrow:=P.kicker(top,"City report");eyebrow.size_flags_horizontal=SIZE_EXPAND_FILL;eyebrow.size_flags_vertical=SIZE_SHRINK_CENTER
	var close:=P.button(top,"Close",_close);close.name="Close";close.size_flags_horizontal=SIZE_SHRINK_END;close.custom_minimum_size=Vector2(88,34);close.tooltip_text="Close (Esc, or click the map)"
	var identity:=HBoxContainer.new();identity.add_theme_constant_override("separation",10);root.add_child(identity)
	flag=TextureRect.new();flag.custom_minimum_size=Vector2(48,42);flag.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;flag.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;identity.add_child(flag)
	var names:=VBoxContainer.new();names.size_flags_horizontal=SIZE_EXPAND_FILL;names.add_theme_constant_override("separation",0);identity.add_child(names)
	selector=OptionButton.new();selector.fit_to_longest_item=false;selector.clip_text=true;selector.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;selector.custom_minimum_size.y=38
	T.text(selector,"voice",T.INK)
	selector.add_theme_stylebox_override("normal",T.flat(Color.TRANSPARENT,Color.TRANSPARENT,0,2));selector.add_theme_stylebox_override("hover",T.flat(T.HOVER_BG,Color.TRANSPARENT,0,2))
	selector.tooltip_text="Other cities of theirs our scouts have reported"
	names.add_child(selector)
	title=P.label(names,"","value",T.INK);title.hide()
	control_label=P.label(names,"","small",T.BODY)
	for city:Dictionary in WorldSimulation.world.city_intelligence.known_cities("player",civ_id):
		selector.add_item(String(city.name));selector.set_item_metadata(selector.item_count-1,String(city.city_id))
		if city.city_id==city_id:selector.select(selector.item_count-1)
	selector.item_selected.connect(func(_i:int):_scouting_signature="";refresh())
	summary=P.label(root,"","small",T.BODY)
	var body:=P.scroll_body(root,10)
	_metric(body,"population",true)
	grid=GridContainer.new();grid.columns=2;grid.size_flags_horizontal=SIZE_EXPAND_FILL;grid.add_theme_constant_override("h_separation",8);grid.add_theme_constant_override("v_separation",8);body.add_child(grid)
	for key:String in V.shown_keys():
		if key!="population":_metric(grid,key)
	detail_button=P.button(body,"About this report",func():detail_text.visible=not detail_text.visible)
	detail_text=P.label(body,"","small",T.BODY);detail_text.hide()
	P.rule(root)
	var actions:=VBoxContainer.new();actions.name="Actions";actions.add_theme_constant_override("separation",6);root.add_child(actions)
	P.kicker(actions,"Talk it over in court")
	var talk_row:=HBoxContainer.new();talk_row.add_theme_constant_override("separation",6);actions.add_child(talk_row)
	talk_ruler=P.button(talk_row,"Talk to their ruler",_talk_to_ruler,true);talk_ruler.name="TalkRuler"
	talk_general=P.button(talk_row,"Talk to our war leader",_talk_to_general);talk_general.name="TalkGeneral"
	war_box=VBoxContainer.new();war_box.add_theme_constant_override("separation",6);actions.add_child(war_box)
	P.kicker(actions,"Keep an eye on it")
	scouting_box=VBoxContainer.new();scouting_box.name="Scouting";scouting_box.add_theme_constant_override("separation",6);actions.add_child(scouting_box)
	var more:=HBoxContainer.new();more.add_theme_constant_override("separation",6);actions.add_child(more)
	P.button(more,"Show on the map",_show_map)
	P.button(more,"Open scouting",_open_scouting)
	feedback=P.label(root,"","small",T.BODY);feedback.hide()
	resized.connect(_layout);_layout()
	var world:=CityEncounterWorld.terrain(get_tree().root)
	var known:Dictionary=WorldSimulation.world.city_intelligence.known("player",city_id)
	if world!=null and not known.is_empty() and WorldSimulation.military.active_engagement.is_empty():
		world.camera.size=maxf(.22,preload("res://scripts/foreign_settlement_visual.gd").framing_size(known))
		world._set_camera_target(Vector3(known.position.x,0,known.position.z));world._refresh_contact_encounter_markers()
	refresh()

func _close()->void:
	if get_parent()!=null and get_parent() is CanvasLayer:get_parent().queue_free()
	else:queue_free()
func _show_map()->void:
	var scene:=get_tree().current_scene
	if scene and scene.has_method("_focus_known_city"):scene._focus_known_city(city_id)
func _open_scouting()->void:
	var scene:=get_tree().current_scene
	if scene and scene.has_method("_open_scout_dispatch_panel"):_close();scene._open_scout_dispatch_panel()
func owner_id()->String:
	var city:Dictionary=WorldSimulation.world.city_intelligence.known("player",city_id)
	var owner:=String(city.get("controller",""))
	return owner if owner!="" else String(city.get("civ_id",""))
func _talk_to_ruler()->void:
	var owner:=owner_id()
	if owner=="" or owner=="player":_say("Who holds this place is not yet known. A fresh report may tell us.");return
	_close();P.talk_to_ruler(owner)
func _talk_to_general()->void:
	var leader:=P.war_leader()
	_close();P.summon(leader.get("target",{}))
func _say(text:String)->void:
	feedback.text=text;feedback.visible=text!=""

func _war_actions(_city:Dictionary)->void:
	var m:=WorldSimulation.military
	var signature:=city_id+str(m.active_siege.get("region_id",""))+str(m.active_engagement.get("status",""))+str(m.pending_aftermath.size())+JSON.stringify(m.occupation_forces.map(func(f:Dictionary)->String:return "%s:%d" % [f.get("region_id",""),int(f.get("troops",0))]))
	if signature==_war_signature:return
	_war_signature=signature
	for child in war_box.get_children():war_box.remove_child(child);child.queue_free()
	siege_button=null;garrison_button=null;aftermath_button=null
	var military:=WorldSimulation.military
	if not military.active_siege.is_empty() and String(military.active_siege.get("region_id",""))==city_id:
		P.label(war_box,"Our army is besieging this city. Its general runs the siege; the briefing shows how it stands.","small",T.BODY)
		siege_button=P.button(war_box,"Siege briefing",func():_close();preload("res://scripts/hud/siege_screen.gd").open())
	elif not military.active_engagement.is_empty() and String((military.active_engagement.get("threat",{}) as Dictionary).get("target_region_id",""))==city_id:
		P.label(war_box,"Our soldiers are fighting here now.","small",T.BODY)
		P.button(war_box,"Watch the battle",func():_close();MilitaryCommandUI.call_deferred("_open_battle_graphics"))
	for force:Dictionary in military.occupation_forces:
		if String(force.get("region_id",""))==city_id and int(force.get("troops",0))>0:
			P.label(war_box,"We hold this city. %d of our soldiers keep it as a garrison." % int(force.troops),"small",T.BODY)
			var civ:=String(force.civ_id)
			garrison_button=P.button(war_box,"Garrison briefing",func():_close();preload("res://scripts/hud/occupation_view.gd").open(civ,city_id))
			break
	if not military.pending_aftermath.is_empty():
		aftermath_button=P.button(war_box,"Review the last battle",func():
			var scene:=get_tree().current_scene
			_close()
			if scene and scene.has_method("_open_war_planning"):scene._open_war_planning())
	war_box.visible=war_box.get_child_count()>0

func _scouting_actions()->void:
	var watch:Dictionary=WorldSimulation.world.scouting_staff.city_watch(city_id)
	var signature:=city_id+JSON.stringify(watch)+str(Orders.party_away(city_id).get("mission_id",-1))+str(int(WorldSimulation.state.elapsed_days))
	if signature==_scouting_signature:return
	_scouting_signature=signature
	for child in scouting_box.get_children():child.queue_free()
	var items:=Orders.dock_items(city_id,func():_scouting_signature="";_say(Orders.dock_status(city_id));refresh())
	if items.is_empty():
		P.label(scouting_box,"Our scouts cannot be sent to this place.","small",T.BODY)
		return
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",6);scouting_box.add_child(row)
	for item:Dictionary in items:
		var button:=P.button(row,String(item.label),item.on_press,bool(item.get("primary",false)))
		button.disabled=bool(item.get("disabled",false))
		button.tooltip_text=String(item.get("tip",""))
	var status:=Orders.dock_status(city_id)
	if status=="":status=String(items[0].get("sub",""))
	if status!="":P.label(scouting_box,status,"small",T.BODY)

func refresh()->void:
	if selector.item_count==0:
		title.show();title.text="No reported cities";summary.text="A scout must first come home with word of a city.";talk_ruler.disabled=true;war_box.hide();return
	city_id=String(selector.get_selected_metadata())
	var city:Dictionary=WorldSimulation.world.city_intelligence.known("player",city_id)
	var today:=int(WorldSimulation.state.elapsed_days)
	title.text=String(city.name).trim_prefix("Reported home of ").capitalize()
	selector.tooltip_text=String(city.name)
	var fields:Dictionary=city.fields
	var freshness:=V.freshness(city,today)
	var observed:=int(city.get("observed_day",-1))
	var observed_days:=int(city.get("observation_days",0))
	if observed<0:summary.text="We know where it is, but no one has looked inside yet."
	else:
		summary.text="Seen in %s; the word reached us %s." % [When.when(observed),When.ago(int(city.get("reported_day",observed)))]
		if int(freshness.level)<=2:summary.text+=" Much may have changed since."
	detail_button.text="About this report"+(" (%s watching)" % When.span(observed_days) if observed_days>0 else "")
	var how:="Our scouts watched it for %s. Time on the road does not sharpen the count; only time spent watching does." % When.span(observed_days) if observed_days>0 else "This older report did not say how long they watched."
	detail_text.text="Brought by %s. %s These figures are what they saw then, not what is true now." % [String(city.source).to_lower() if String(city.source)!="" else "our scouts",how]
	var identity_id:=String(city.controller) if not String(city.controller).is_empty() else String(city.civ_id)
	flag.texture=IDENTITY.emblem(identity_id)
	var owner:=owner_id()
	control_label.text="Held by "+WorldSimulation.world.city_intelligence.controller_label(String(city.controller))
	# A town we hold says so as the map does: whose it was, since when, who guards it.
	var held:=preload("res://scripts/map_ownership.gd").status(city)
	if String(held.kind)=="occupied":control_label.text="%s · %s" % [String(held.line),String(held.note)] if not String(held.note).is_empty() else String(held.line)
	var owner_index:=WorldSimulation.world._civilization_index(owner)
	if owner_index>=0:
		var relation:Dictionary=WorldSimulation.world.civilizations[owner_index].player_relation
		control_label.text+=" · "+("at war with us" if bool(relation.get("at_war",false)) else "at peace with us")
	for key:String in cards:
		var field:Dictionary=fields.get(key,{})
		var value:Label=cards[key].value;var note:Label=cards[key].note
		cards[key].name.text=V.label(key)
		value.text=V.words(key,field)
		var seen:=int(field.get("observed_day",-1))
		note.text=String(V.MEANINGS.get(key,"")) if field.is_empty() or seen==observed else "%s Seen %s." % [String(V.MEANINGS.get(key,"")),When.ago(seen)]
		cards[key].card.tooltip_text=String(INTEL.FIELDS[key].label)
	var pop:Dictionary=fields.get("population",{})
	projection.text=""
	if not pop.is_empty() and int(pop.get("age_days",0))>0:
		var now:=V.bounds(pop,false)
		projection.text="By now it could be %s." % V.words("population",{"low":now.x,"high":now.y})
	if int(pop.get("age_days",0))>1095:projection.text="After this long, no one can say how many live there now."
	projection.visible=not projection.text.is_empty() and int(freshness.received_age)>90
	var ruler:=P.ruler_name(owner) if owner!="player" else ""
	talk_ruler.text="Talk to "+P.first_name(ruler) if ruler!="" else "Send word to their ruler"
	talk_ruler.disabled=owner=="" or owner=="player"
	talk_ruler.tooltip_text="Opens the court, where your envoys carry your words to them." if not talk_ruler.disabled else "Who holds this place is not yet known."
	var leader:=P.war_leader()
	talk_general.visible=not leader.is_empty()
	talk_general.text="Talk to %s" % P.first_name(String(leader.get("name",""))) if not leader.is_empty() else "Talk to our war leader"
	talk_general.tooltip_text="Your war leader decides how to fight. Tell them in court what you want done about this city."
	_war_actions(city)
	_scouting_actions()

func _process(delta:float)->void:
	timer+=delta
	if timer>=5:timer=0;refresh()
func _unhandled_input(event:InputEvent)->void:
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:_close();get_viewport().set_input_as_handled()
